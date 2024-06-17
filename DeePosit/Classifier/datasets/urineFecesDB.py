import numpy as np
import os
from PIL import Image
import torch
import cv2
import xml.etree.ElementTree as ET


class FecesUrineIrDb:
    def __init__(self, img_folder, ann_folder, ann_file, transforms=None):
        self.img_folder = img_folder
        self.folderList = [os.path.join(self.img_folder, item) for item in os.listdir(self.img_folder) if os.path.isdir(os.path.join(self.img_folder, item))]
        self.transforms = None
    def getFolderForIdx(self,idx):
        return self.folderList[idx]

    def __getitem__(self, idx):
        currentFolder = self.folderList[idx]

        baseName = os.path.basename(currentFolder)
        if baseName.find('Shifted') == 0:
            label = 3
        elif baseName.find('Feces')==0:
            label = 2
        elif baseName.find('Urine')==0:
            label = 1
        elif baseName.find('BG') == 0:
            label = 0
        else:
            raise Exception(baseName + " is non valid directory")

        imgList = [os.path.join(currentFolder, item) for item in os.listdir(currentFolder) if item.startswith('RGBImg_F')]
        #select a random image from the imgList:
        randInd = np.random.randint(0,len(imgList))
        #imgRGB = np.asarray(Image.open(imgList[randInd]))
        imgRGB = np.asarray(cv2.imread(imgList[randInd], cv2.IMREAD_UNCHANGED))

        imgRGB = (imgRGB.astype('single')-27315.0)/100.0 #celsius
        imgRGB = np.clip( ((imgRGB - 10.0) / (40-10))*255 ,0,255)# normalize between 10 and 40 deg celsius
        img = torch.tensor(imgRGB)
        h,w = img.size()[0:2]
        img = torch.permute(img,[2,0,1])

        target = {}
        target['image_id'] = torch.tensor(idx)
        target['labels'] = torch.tensor([label])
        target["boxes"] = torch.tensor([[0.5, 0.5, 0.2, 0.2]])
        target['size'] = torch.as_tensor([int(h), int(w)])
        target['orig_size'] = torch.as_tensor([int(h), int(w)])

        if self.transforms is not None:
            img, target = self.transforms(img, target)

        return img, target, currentFolder

    def __len__(self):
        return len(self.folderList)

    def get_height_and_width(self, idx):
        #img_info = self.coco['images'][idx]
        height = 65
        width = 1755
        return height, width


#image vec dimensions: [batchSize, channels, height, width]
#output dimensions: [batchSize, RGB, height, width*channels/3]
def ImgVecToRGBFormat(imgVec):

    batchSize = imgVec.shape[0]
    nChannels = imgVec.shape[1]
    height = imgVec.shape[2]
    width = imgVec.shape[3]
    rgbImg = torch.zeros(batchSize,3,height,width*nChannels/3,device=imgVec.device,dtype=imgVec.dtype)

    startX = 0
    rgbI = 0
    for k in range(nChannels):
        rgbImg[:,rgbI,:,startX:startX+width] = imgVec[:,k,:,:]
        rgbI = (rgbI+1)%3
        if rgbI==0:
            startX = startX+width



class FecesUrineIrDbFullVid:
    def __init__(self, video_folder, ann_folder, ann_file, timeStepFrame, spatialStepPixel, transforms=None):
        self.video_folder = video_folder
        #self.folderList = [os.path.join(self.img_folder, item) for item in os.listdir(self.img_folder) if os.path.isdir(os.path.join(self.img_folder, item))]
        self.imgList =  [item for item in os.listdir(self.video_folder) if item.endswith('.bin') and not item.startswith('NUC')]
        #usedFramesInd = np.arange(0, len(self.imgList), timeStepFrame,dtype=np.int32)
        #self.imgList = [self.imgList[t] for t in usedFramesInd]

        self.transforms = None
        self.frameHeight = 288
        self.frameWidth = 384
        self.xmlFileName = os.path.join(video_folder,'BBandCageContours.xml')
        self.winSizeX = 64
        self.winSizeY = 64
        self.winR = self.winSizeX/2
        [self.meshX,self.meshY] = np.meshgrid(np.arange(self.winR,self.frameWidth-self.winR,spatialStepPixel), np.arange(spatialStepPixel,self.frameHeight-self.winR,spatialStepPixel))
        self.nExamplesPerFrame = len(self.meshX)

        step = 9
        self.nFramesBefore = 20
        self.nFramesAfter = 60

        timeStep = 9
        self.FramesCenterT = np.arange(0,len(self.imgList) , timeStep)
        self.startFrame = 0
        self.endFrame = len(self.imgList)-1 #inclusive
        self.step = 9
        self.LoadVideoToMem()

    def LoadVideoToMem(self):
        self.imgsInMemInd = np.arange(self.startFrame,self.endFrame+1,self.step)
        nImgs = len(self.imgsInMemInd)
        self.imgArray = np.zeros((self.imgHeight,self.imgWidth,nImgs),dtype=np.single)
        for t in range(nImgs):
            self.imgArray[:,:,t] = self.readImg(self.imgsInMemInd[t])

    def __getitem__(self, idx):

        startInd = idx - self.nFramesBefore
        endInd = idx + self.nFramesAfter #inclusive
        nImgs = endInd - startInd +1

        imgVec = torch.zeros((288,384,nImgs),dtype=torch.single)
        usedIndImgArray = np.arange( max(0,startInd), min(self.imgArray.shape[2],endInd+1) , 1)

        endImgVec = endInd + 1
        if startInd <0:
            endImgVec =  endImgVec + startInd
        startImgVec = startInd
        if endInd >= self.imgArray.shape[2]:
            startImgVec = startImgVec + (endInd-self.imgArray.shape[2]-1)
        usedIndImgVec = np.arange( startImgVec, endImgVec , 1)

        imgVec[:,:,usedIndImgVec] = torch.tensor(self.imgArray[:,:,usedIndImgArray])

        label = 0

        h,w = imgVec.size()[0:2]
        imgVec = torch.permute(imgVec,[2,0,1])

        target = {}
        target['image_id'] = torch.tensor(idx)
        target['labels'] = torch.tensor([label])
        target["boxes"] = torch.tensor([[0.5, 0.5, 0.2, 0.2]])
        target['size'] = torch.as_tensor([int(h), int(w)])
        target['orig_size'] = torch.as_tensor([int(h), int(w)])

        if self.transforms is not None:
            img, target = self.transforms(imgVec, target)

        return img, target, self.video_folder


    def readBBandCageContours(self,xmlFileName):
        tree = ET.parse(xmlFileName)
        root = tree.getroot()

        self.habCageX = [np.single(t.text) for t in root.iter('habCageX')]
        self.habCageY = [np.single(t.text) for t in root.iter('habCageY')]

        self.habBbX = [np.single(t.text) for t in root.iter('habBbX')]
        self.habBbY = [np.single(t.text) for t in root.iter('habBbY')]

        self.trialCageX = [np.single(t.text) for t in root.iter('trialCageX')]
        self.trialCageY = [np.single(t.text) for t in root.iter('trialCageY')]

        self.trialBbX = [np.single(t.text) for t in root.iter('trialBbX')]
        self.trialBbY = [np.single(t.text) for t in root.iter('trialBbY')]

        self.trialStartFrame = [np.int32(t.text) for t in root.iter('trialStartFrame')]
        self.trialEndFrame = [np.int32(t.text) for t in root.iter('trialEndFrame')]

        self.habStartFrame = [np.int32(t.text) for t in root.iter('habStartFrame')]
        self.habEndFrame = [np.int32(t.text) for t in root.iter('habEndFrame')]


    def readImg(self,imgIndex):
        #file = open(“document.bin”, ”wb”)
        filename_video = os.path.join(self.video_folder,self.imgList[imgIndex])
        imC = np.memmap(filename_video, dtype=np.uint16, mode='r', shape=(self.frameHeight, self.frameWidth))

        imC = imC.astype(np.single) - self.imgNUC;
        imC = (imC - 27315.0) / 100.0 # celsius

        #TODO:
            #substract the mean value of the black body and add 37

        imC = np.clip(((imC - 10.0) / (40 - 10)) * 255, 0, 255)  #normalize between 10 deg and 40 deg
        return imC


