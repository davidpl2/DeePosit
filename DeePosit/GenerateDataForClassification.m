function [nDetections,detCordX,detCordY,detFrame,detType,detPixels] = GenerateDataForClassification(srcDir,outDir,step,pastSteps,futureSteps)
winRad = 32;
rows = 288;
cols = 384;
%step = 9;
%startFrame = 0- 20*step;
%endFrame = 0+ 60*step;

% step = 8;% was 9
% pastSteps = 20;
% futureSteps = 129;

startFrame = 0- pastSteps*step;
endFrame = 0+ futureSteps*step;

global IrImgVec


outFileName = fullfile(srcDir,'DetectionsVid.avi');
load(fullfile(srcDir,'Detections.mat'));
[rows,cols,nFrames] = size(IrImgVec);
gtCordX = [];
gtCordY = [];
gtFrame = [];
gtType ={};
detPixels={};
for r=1:length(oldRegionsVec)
    if ~oldRegionsVec{r}.regionSaved
        continue
    end
    
    cordI = oldRegionsVec{r}.maxCordI;
    cordJ = oldRegionsVec{r}.maxCordJ;
    frameInd = oldRegionsVec{r}.hotFrame;%firstFrameInd;
    
    gtCordX(end+1) = cordJ;
    gtCordY(end+1) = cordI;
    gtFrame(end+1) = frameInd;
    gtType{end+1} = 'BG';%to be consistant with the data loader
    detPixels{end+1} = oldRegionsVec{r}.PixelIdxList;
end
nDetections = length(gtCordX);


patchMat = zeros(winRad*2+1,winRad*2+1,length(startFrame:step:endFrame),'uint16');
[~,vidName,~] = fileparts(srcDir);
%frameRange = -round(10*fps):round(30*fps);
%detectionGraph = zeros(length(gtCordX),length(frameRange));

for r = 1:length(gtCordX)
    patchMat(:) = 0;
    indPatchMat = 1;
    startFrame = gtFrame(r)- pastSteps*step;
    endFrame = gtFrame(r)+ futureSteps*step;
    indRow = max(1,gtCordY(r)-winRad):min(rows,gtCordY(r)+winRad);
    indCol = max(1,gtCordX(r)-winRad):min(cols,gtCordX(r)+winRad);
    curOutDir = fullfile(outDir,[gtType{r}, '_Frame',num2str(gtFrame(r),'%.5d'),'_X',num2str(gtCordX(r)),'_Y',num2str(gtCordY(r))]);
    mkdir(curOutDir);
    
    for k=startFrame:step:endFrame
        if (k >=1 && k<=size(IrImgVec,3))
            img = IrImgVec(:,:,k);
            %detectionGraph(r,k-startFrame+1) = img(gtCordY(r),gtCordX(r));
            patch = zeros(winRad*2+1,winRad*2+1);
            indPRow = indRow-(gtCordY(r)-winRad)+1;
            indPCol = indCol-(gtCordX(r)-winRad)+1;
            patch(:) = 22;%this is the usual background temprature.
            patch(indPRow,indPCol) = img(indRow,indCol);
            %imC = (curIm - 27315.0)/100.0;%celsius
            resIm = uint16(round(patch*100+27315.0)) ;
            %imwrite(resIm,fullfile(curOutDir,[num2str(k-startFrame+1,'%.4d'),'_',num2str(k,'%.5d'),'.tif']));
        else
            %detectionGraph(r,k-startFrame+1) = 0;
            patch = zeros(winRad*2+1,winRad*2+1);
            patch(:) = 22;
            resIm = uint16(round(patch*100+27315.0)) ;
            %imwrite(resIm,fullfile(curOutDir,[num2str(k-startFrame+1,'%.4d'),'_',num2str(k,'%.5d'),'.tif']));
        end
        patchMat(:,:,indPatchMat) = resIm;
        indPatchMat = indPatchMat+1;
    end
    for doFilp = [0,1]
        for rot = [0,90,180,270]
            RGBImg = GenerateRGBImgFromVid(patchMat,doFilp,rot);
            postfix = ['_F',num2str(doFilp),'_R',num2str(rot),'.tif'];
            imwrite(RGBImg,fullfile(curOutDir,['RGBImg',postfix]));
            dRGB = double(RGBImg) - double(min(RGBImg(:)));
            imwrite(dRGB./max(dRGB(:)),fullfile(curOutDir,['RGBImgForVis',postfix]));
        end
    end
end
detCordX=gtCordX;
detCordY=gtCordY;
detFrame=gtFrame;
detType=repmat({'BG'},size(gtCordX));