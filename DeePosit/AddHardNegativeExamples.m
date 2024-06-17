function AddHardNegativeExamples(RGBResPath,outDir,usedVids,regenerate,isTest)

if nargin ==0
    %RGBResPath = 'E:\ICR Dup\HeuristicResPath1.10Train\';
    %outDir = 'E:\ICR Dup\TrainHardFalseV1.10\'

    RGBResPath = 'E:\ICR Dup\HeuristicResPath1.10_LongVids\'
    outDir = 'E:\ICR Dup\TrainHardFalseV1.10LongVids\'
end
timeAugmentation=false;

%trainVids = [1:31,39:47];

for vidIndex = usedVids
    
    [srcDir,parts,imgsList,imgNUC,handles] = GetVidParts(vidIndex);
    [~,vidName,~] = fileparts(srcDir);
    if isfield(handles,'clickX')
        gtCordX = handles.clickX;
        gtCordY = handles.clickY;
        gtFrame = handles.clickFrame;
        gtType = handles.clickType;
    else
        gtCordX = [];
        gtCordY = [];
        gtFrame = [];
        gtType = {};
    end
            
    rgbDIR = fullfile(RGBResPath,[vidName,'_Hab']);
    dirList =getSubdirList(rgbDIR);
    [detX,detY,detFrames] = getXYFrameFromDirName(dirList); 
    isFalseDet = false(size(detX));
    detTypes = repmat({'BG'},length(isFalseDet),1);
    for k=1:length(detFrames)
        isFalseDet(k) = isFalseDetection(detX(k),detY(k),detFrames(k),gtCordX,gtCordY,gtFrame);
    end
    
    if regenerate
        GenerateDatabaseSingleVid(vidIndex, outDir, detX(isFalseDet), detY(isFalseDet), detFrames(isFalseDet), detTypes(isFalseDet), timeAugmentation,isTest);
    else
        for k=1:length(detFrames)
            if isFalseDetection(detX(k),detY(k),detFrames(k),gtCordX,gtCordY,gtFrame)
                copyfile(fullfile(rgbDIR,dirList(k).name),fullfile(outDir,['BG_',vidName,'_',dirList(k).name(4:end)]));
            end
        end
    end
    
    rgbDIR = fullfile(RGBResPath,[vidName,'_Trial']);
    dirList =getSubdirList(rgbDIR);
    [detX,detY,detFrames] = getXYFrameFromDirName(dirList);  
    isFalseDet = false(size(detX));
    detTypes = repmat({'BG'},length(isFalseDet),1);
    for k=1:length(detFrames)
        isFalseDet(k) = isFalseDetection(detX(k),detY(k),detFrames(k),gtCordX,gtCordY,gtFrame);
    end
    if regenerate
        GenerateDatabaseSingleVid(vidIndex, outDir, detX(isFalseDet), detY(isFalseDet), detFrames(isFalseDet), detTypes(isFalseDet), timeAugmentation,isTest);
    else
        for k=1:length(detFrames)
            if isFalseDet(k)
                copyfile(fullfile(rgbDIR,dirList(k).name),fullfile(outDir,['BG_',vidName,'_',dirList(k).name(4:end)]));
            end
        end
    end
end