function [srcDir,parts,imgsList,imgNUC,handles,predictions,ver,mouseFrameNum, mouseCenterXY] = GetVidParts(vidIndex,classifierVer,HeuristicVer,detectionBaseDir, getImageList)
params = getParams();
%global g_baseDir;
baseDir = params.vidDir;
if ~exist(baseDir)
    error('data folder does not exist');
end

if ~exist('detectionBaseDir','var')
    detectionBaseDir = params.detDir;
end

if ~exist('getImageList','var')
    getImageList = true; %getImageList can be set to false to reduce run time. in this case, outputs imgsList and imgNUC will be []
end



handles=[];

% baseDir1 = 'E:\ICR Dup\';
% baseDir2 = 'S:\Natalie\ICR Dup\';
% 
% baseDir = baseDir1;
% if ~exist(baseDir)
%     baseDir = baseDir2;
%     if ~exist(baseDir)
%         error('data folder does not exist');
%     end
% end
%disp(['baseDir=',baseDir]);
vidsTable = readtable(fullfile(baseDir,'vidsID.csv'),'delimiter',',');
dirList = vidsTable.vidDir;
for k=1:length(dirList)
    dirList{k} = fullfile(baseDir,dirList{k});
end

detDir = fullfile(detectionBaseDir,vidsTable.vidDir{vidIndex});
    
if 0
    %save to excel
    vidId = 1:length(dirList);
    vidDir = dirList';
    vidId = vidId';
    T = table(vidId,vidDir);
    writetable(T,'E:\vidsID.csv');
end
if 0
    vidPath = dirList'
    vidId = (1:length(vidPath))'
    T1 = table(vidId);
    T2 = [T1,cell2table(vidPath)];
    writetable(T2,'E:\vidList.xlsx');
end
srcDir = dirList{vidIndex};

handles = loadBBandCageContours(srcDir,[]);

partEmpty = struct('name','empty'  ,'frames',[0   , 0 ],'valid',false,'shifted',nan);
partHab   = struct('name','Habituation'  ,'frames',handles.habFrames,'valid',true,'shifted',nan,'cageMask',handles.habCageMask,'bbMask',handles.habBbMask);
partTrial = struct('name','SNP',         'frames',handles.trialFrames,'valid',true,'shifted',nan,'cageMask',handles.trialCageMask,'bbMask',handles.trialBbMask);
part1 = partEmpty;
part2 = partEmpty;
part3 = partHab;
part4 = partEmpty;
part5 = partTrial;

parts = {part1,part2,part3,part4,part5};

rows = 288;
cols = 384;
dtype = 'uint16';
%
% for k=1:length(parts)
%     if ~parts{k}.valid
%         continue;
%     end
%     startI = parts{k}.frames(1);
%     if vidIndex<=8
%         parts{k}.cageMaskFile = fullfile(srcDir,['cageMask_',num2str(parts{k}.frames(1)),'.bmp']);
%         parts{k}.bbMaskFile = fullfile(srcDir,['bbMask_',num2str(parts{k}.frames(1)),'.bmp']);
%     end
% end
if getImageList
    fnamesNuc = dir(fullfile(srcDir,'NUC*.bin'));
    if length(fnamesNuc)>1
        disp('several nuc files. taking the last one');
        fnamesNuc = fnamesNuc(end);
    end
    if length(fnamesNuc)>=1
        nucFname = fullfile(srcDir,fnamesNuc(1).name);
        %disp(['using Nuc file: ',nucFname])
        imgNUC = bImread(nucFname,rows,cols,'float32');
        imgNUC = imgNUC-mean(imgNUC(:));
    else
        imgNUC = zeros(288,384,'single');
        warning('no nuc file');
    end
    
    %%%start analysis%%%%%%%%%%%%%%%%%%%%%%
    imgsList = dir(fullfile(srcDir,'*.bin'));
    isNucIm = false(length(imgsList),1);
    for k=1:length(imgsList)
        isNucIm(k) = isequal(imgsList(k).name(1:3),'NUC');
    end
    imgsList = imgsList(~isNucIm);
    
    imgId = getImgId(imgsList);
    [~,ind] = sort(imgId,'ascend');
    imgsList = imgsList(ind);
else
    imgsList=[];
    imgNUC=[];
end



GT_DetectionsFile = fullfile(srcDir,'GT_Detections.xlsx');
if exist(GT_DetectionsFile,'file')
    T = readtable(GT_DetectionsFile);
    handles.clickX = T.x;
    handles.clickY = T.y;
    handles.clickFrame = T.frameIndex;
    handles.clickType = T.type;
end

predictions = [];
if ~isempty(classifierVer) && ~isempty(HeuristicVer)
    [predictedLabelAll,autoFrameIDAll,autoCordXAll,autoCordYAll,ver, autoAreaAll,maxPixelIdxListAll,...
        mouseFrameNum, mouseCenterXY,unifiedPixelIdxListAll] = ReadAutoDetections(detDir,false,false,classifierVer,HeuristicVer);
    predictions.label = predictedLabelAll;
    predictions.frame = autoFrameIDAll;
    predictions.x = autoCordXAll;
    predictions.y = autoCordYAll;
    predictions.area = autoAreaAll;
    predictions.PixelIdxList = maxPixelIdxListAll;
    predictions.unifiedPixelIdxList = unifiedPixelIdxListAll;
end
% 
% habDetectionsTable = [];
% trialDetectionsTable = [];
% resDir = dir(fullfile(srcDir,'*Habituation1.4LowThres'));
% if length(resDir)>0
%     curFname = fullfile(srcDir,resDir(1).name,'Test_V2_Epoch_-1.csv');
%     if exist(curFname,'file')
%         habDetectionsTable = readtable(curFname,'Delimiter',','); 
%     end
% end
% 
% resDir = dir(fullfile(srcDir,'*Trial1.4LowThres'));
% if length(resDir)>0
%     curFname = fullfile(srcDir,resDir(1).name,'Test_V2_Epoch_-1.csv');
%     if exist(curFname,'file')
%         trialDetectionsTable = readtable(curFname,'Delimiter',','); 
%     end
% end
