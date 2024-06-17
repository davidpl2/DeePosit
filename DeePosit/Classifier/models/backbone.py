# Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved
"""
Backbone modules.
"""
from collections import OrderedDict

import torch
import torch.nn.functional as F
import torchvision
from torch import nn
from torchvision.models._utils import IntermediateLayerGetter
from typing import Dict, List

from util.misc import NestedTensor, is_main_process

from .position_encoding import build_position_encoding


class FrozenBatchNorm2d(torch.nn.Module):
    """
    BatchNorm2d where the batch statistics and the affine parameters are fixed.

    Copy-paste from torchvision.misc.ops with added eps before rqsrt,
    without which any other models than torchvision.models.resnet[18,34,50,101]
    produce nans.
    """

    def __init__(self, n):
        super(FrozenBatchNorm2d, self).__init__()
        self.register_buffer("weight", torch.ones(n))
        self.register_buffer("bias", torch.zeros(n))
        self.register_buffer("running_mean", torch.zeros(n))
        self.register_buffer("running_var", torch.ones(n))

    def _load_from_state_dict(self, state_dict, prefix, local_metadata, strict,
                              missing_keys, unexpected_keys, error_msgs):
        num_batches_tracked_key = prefix + 'num_batches_tracked'
        if num_batches_tracked_key in state_dict:
            del state_dict[num_batches_tracked_key]

        super(FrozenBatchNorm2d, self)._load_from_state_dict(
            state_dict, prefix, local_metadata, strict,
            missing_keys, unexpected_keys, error_msgs)

    def forward(self, x):
        # move reshapes to the beginning
        # to make it fuser-friendly
        w = self.weight.reshape(1, -1, 1, 1)
        b = self.bias.reshape(1, -1, 1, 1)
        rv = self.running_var.reshape(1, -1, 1, 1)
        rm = self.running_mean.reshape(1, -1, 1, 1)
        eps = 1e-5
        scale = w * (rv + eps).rsqrt()
        bias = b - rm * scale
        return x * scale + bias


class BackboneBase(nn.Module):

    def __init__(self, backbone: nn.Module, train_backbone: bool, num_channels: int, return_interm_layers: bool):
        super().__init__()
        for name, parameter in backbone.named_parameters():
            if not train_backbone or 'layer2' not in name and 'layer3' not in name and 'layer4' not in name:
                parameter.requires_grad_(False)
        if return_interm_layers:
            return_layers = {"layer1": "0", "layer2": "1", "layer3": "2", "layer4": "3"}
        else:
            return_layers = {'layer4': "0"}
        self.body = IntermediateLayerGetter(backbone, return_layers=return_layers)
        self.num_channels = num_channels

    def forward(self, tensor_list: NestedTensor):
        xs = self.body(tensor_list.tensors)
        out: Dict[str, NestedTensor] = {}
        for name, x in xs.items():
            m = tensor_list.mask
            assert m is not None
            mask = F.interpolate(m[None].float(), size=x.shape[-2:]).to(torch.bool)[0]
            out[name] = NestedTensor(x, mask)
        return out

class BackboneBaseMultiIm(nn.Module):

    def __init__(self, backbone: nn.Module, train_backbone: bool, num_channels: int, return_interm_layers: bool):
        super().__init__()
        for name, parameter in backbone.named_parameters():
            if not train_backbone or 'layer2' not in name and 'layer3' not in name and 'layer4' not in name:
                parameter.requires_grad_(False)
        if return_interm_layers:
            return_layers = {"layer1": "0", "layer2": "1", "layer3": "2", "layer4": "3"}
        else:
            return_layers = {'layer4': "0"}
        self.body = IntermediateLayerGetter(backbone, return_layers=return_layers)
        self.num_channels = num_channels

    def forward(self, tensor_list: NestedTensor):
        sizeY = tensor_list.tensors.shape[2]#dimensions are: batch,rgb,sizeY,sizeX
        sizeX = tensor_list.tensors.shape[3]
        imgSize = 65
        if sizeY>imgSize:
            borderLeft = torch.randint(sizeY-imgSize+1,(1,1)).squeeze()
            borderTop  = torch.randint(sizeY-imgSize+1,(1,1)).squeeze()
        else:
            borderLeft = 0
            borderTop = 0

        nImgs = int(sizeX/sizeY)
        outAll = []
        c=0
        for i in range(nImgs):

            xs = self.body(tensor_list.tensors[:,:,borderTop:borderTop+imgSize,c+borderLeft:c+borderLeft+imgSize])
            out: Dict[str, NestedTensor] = {}
            for name, x in xs.items():
                m = tensor_list.mask
                assert m is not None
                mask = F.interpolate(m[None].float(), size=x.shape[-2:]).to(torch.bool)[0]
                out[name] = NestedTensor(x, mask)
            c = c+sizeY
            outAll.append(out)

        return outAll
#
# class BackboneBaseFullFrame(nn.Module):
#
#     def __init__(self, backbone: nn.Module, train_backbone: bool, num_channels: int, return_interm_layers: bool):
#         super().__init__()
#         for name, parameter in backbone.named_parameters():
#             if not train_backbone or 'layer2' not in name and 'layer3' not in name and 'layer4' not in name:
#                 parameter.requires_grad_(False)
#         if return_interm_layers:
#             return_layers = {"layer1": "0", "layer2": "1", "layer3": "2", "layer4": "3"}
#         else:
#             return_layers = {'layer4': "0"}
#         self.body = IntermediateLayerGetter(backbone, return_layers=return_layers)
#         self.num_channels = num_channels
#
#     def forward(self, tensor_list: NestedTensor):
#         sizeY = tensor_list.tensors.shape[2]#dimensions are: batch,channels,sizeY,sizeX
#         sizeX = tensor_list.tensors.shape[3]
#         nImgs = tensor_list.tensors.shape[1]
#
#         winR = 32
#         spatialStepPixel = 32
#         [self.meshX,self.meshY] = np.meshgrid(np.arange(winR,sizeX-winR,spatialStepPixel), np.arange(spatialStepPixel,self.frameHeight-self.winR,spatialStepPixel))
#
#         outAll = []
#         c=0
#         for i in range(nImgs):
#
#             xs = self.body(tensor_list.tensors[:,:,:,c:c+sizeY])
#             out: Dict[str, NestedTensor] = {}
#             for name, x in xs.items():
#                 m = tensor_list.mask
#                 assert m is not None
#                 mask = F.interpolate(m[None].float(), size=x.shape[-2:]).to(torch.bool)[0]
#                 out[name] = NestedTensor(x, mask)
#             c = c+sizeY
#             outAll.append(out)
#
#         return outAll

class JoinerMultiIm(nn.Sequential):
    def __init__(self, backbone, position_embedding):
        super().__init__(backbone, position_embedding)

    def forward(self, tensor_list: NestedTensor):
        xsAll = self[0](tensor_list)
        outAll = []
        posAll = []
        for k in range(len(xsAll)):
            xs = xsAll[k]
            out: List[NestedTensor] = []
            pos = []
            for name, x in xs.items():
                out.append(x)
                # position encoding
                timeStamp = (k+1)/len(xsAll)
                pos.append(self[1](x,timeStamp).to(x.tensors.dtype))
            outAll.append(out)
            posAll.append(pos)

        #to keep the same format, concatenate in the x axis:
        out: List[NestedTensor] = []
        pos = []
        for i in range(len(outAll[0])):
            curOutFtrsList = [outAll[k][i].decompose()[0] for k in range(len(outAll))]
            curOutMaskList   = [outAll[k][i].decompose()[1] for k in range(len(outAll))]
            curPosList = [posAll[k][i] for k in range(len(posAll))]

            outFtrs=torch.cat(curOutFtrsList, axis=3)
            outMask=torch.cat(curOutMaskList, axis=2)
            out.append(NestedTensor(outFtrs,outMask))
            pos.append(torch.cat(curPosList, axis=3))

        return out, pos

class BackboneMultiIm(BackboneBaseMultiIm):
    """ResNet backbone with frozen BatchNorm."""
    def __init__(self, name: str,
                 train_backbone: bool,
                 return_interm_layers: bool,
                 dilation: bool):
        backbone = getattr(torchvision.models, name)(
            replace_stride_with_dilation=[False, False, dilation],
            pretrained=is_main_process(), norm_layer=FrozenBatchNorm2d)
        num_channels = 512 if name in ('resnet18', 'resnet34') else 2048
        super().__init__(backbone, train_backbone, num_channels, return_interm_layers)

class Backbone(BackboneBase):
    """ResNet backbone with frozen BatchNorm."""
    def __init__(self, name: str,
                 train_backbone: bool,
                 return_interm_layers: bool,
                 dilation: bool):
        backbone = getattr(torchvision.models, name)(
            replace_stride_with_dilation=[False, False, dilation],
            pretrained=is_main_process(), norm_layer=FrozenBatchNorm2d)
        num_channels = 512 if name in ('resnet18', 'resnet34') else 2048
        super().__init__(backbone, train_backbone, num_channels, return_interm_layers)


class Joiner(nn.Sequential):
    def __init__(self, backbone, position_embedding):
        super().__init__(backbone, position_embedding)

    def forward(self, tensor_list: NestedTensor):
        xs = self[0](tensor_list)
        out: List[NestedTensor] = []
        pos = []
        for name, x in xs.items():
            out.append(x)
            # position encoding
            pos.append(self[1](x).to(x.tensors.dtype))

        return out, pos


def build_backbone(args):
    useMultiIm = True

    position_embedding = build_position_encoding(args,useMultiIm)
    train_backbone = args.lr_backbone > 0
    return_interm_layers = args.masks

    if useMultiIm:
        backbone = BackboneMultiIm(args.backbone, train_backbone, return_interm_layers, args.dilation)
        model = JoinerMultiIm(backbone, position_embedding)
    else:
        backbone = Backbone(args.backbone, train_backbone, return_interm_layers, args.dilation)
        model = Joiner(backbone, position_embedding)
    model.num_channels = backbone.num_channels
    return model
