function GenerateDatabaseSingleVid(vidIndex, outDir, gtCordX, gtCordY, gtFrame, gtType, timeAugmentation,isTest,vidLoadedToMem,step,pastSteps,futureSteps)
rng(0);
global IrImgVec

if isTest
    winRad = 32;%32
else    
    winRad = 34;%32
end
rows = 288;
cols = 384;
fps = 8.663;

if 0 
    timeAug = round(-3*fps):2:round(12*fps);
else
    timeAug = round(-3*fps):2:round(6*fps);
end


mkdir(outDir);

startFrame = 0- pastSteps*step;
endFrame = 0+ futureSteps*step;
        
patchMat = zeros(winRad*2+1,winRad*2+1,length(startFrame:step:endFrame),'uint16');
[srcDir,parts,imgsList,imgNUC,handles] = GetVidParts(vidIndex,[],[]);
if ~handles.tagFinished
    error(['tagging not done. skipping. ',srcDir]);
end            
[~,vidName,~] = fileparts(srcDir);
habFrames = handles.habFrames;
trialFrames = handles.trialFrames;        

[imgsList,imgNUC] = GetImageListAndNucIm(srcDir);
[~,lastHabMeanBB] = GetImage(srcDir, imgsList, habFrames(2), imgNUC , handles.habBbMask);
frameRange = -round(10*fps):round(30*fps);
detectionGraph = zeros(length(gtCordX),length(frameRange));

%allFrmaes = cell(1,length(imgsList));
for r = 1:length(gtCordX)
    
    if timeAugmentation
        timeAugVec = timeAug;     
    else
        timeAugVec = [0];
    end

    for augTi = 1:length(timeAugVec)
        if timeAugmentation
            curAugT = timeAug(augTi);
        else
            curAugT = 0;
        end

        patchMat(:) = 0;
        indPatchMat = 1;

        %startFrame = gtFrame(r)-round(20*fps);
        %endFrame = gtFrame(r)+round(60*fps);

        startFrame = gtFrame(r)- pastSteps*step + curAugT;
        endFrame = gtFrame(r)+ futureSteps*step + curAugT;

        indRow = max(1,gtCordY(r)-winRad):min(rows,gtCordY(r)+winRad);
        indCol = max(1,gtCordX(r)-winRad):min(cols,gtCordX(r)+winRad);

        curOutDir = fullfile(outDir,[gtType{r}, '_Vid',num2str(vidIndex,'%.3d'),'_Frame',num2str(gtFrame(r)),'_X',num2str(gtCordX(r)),'_Y',num2str(gtCordY(r)),'_D',num2str(r),'_AugT',num2str(curAugT),'_V',vidName]);
        mkdir(curOutDir);

        for k=startFrame:step:endFrame
            if (k >=1 && k<=length(imgsList))
                if vidLoadedToMem
                    img = IrImgVec(:,:,k);
                elseif k<=habFrames(2)                
                    img = GetImage(srcDir, imgsList, k, imgNUC , handles.habBbMask);
                elseif k>=trialFrames(1)
                    img = GetImage(srcDir, imgsList, k, imgNUC , handles.habBbMask);
                else
                    img = GetImage(srcDir, imgsList, k, imgNUC , []);
                    img = img-lastHabMeanBB + 37;
                end
                detectionGraph(r,k-startFrame+1) = img(gtCordY(r),gtCordX(r));

                patch = zeros(winRad*2+1,winRad*2+1);
                indPRow = indRow-(gtCordY(r)-winRad)+1;
                indPCol = indCol-(gtCordX(r)-winRad)+1;
                patch(:) = 22;%this is the usual background temprature.
                patch(indPRow,indPCol) = img(indRow,indCol);     
                %imC = (curIm - 27315.0)/100.0;%celsius
                resIm = uint16(round(patch*100+27315.0)) ;
                %imwrite(resIm,fullfile(curOutDir,[num2str(k-startFrame+1,'%.4d'),'_',num2str(k,'%.5d'),'.tif']));                
            else
                detectionGraph(r,k-startFrame+1) = 0;

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
end