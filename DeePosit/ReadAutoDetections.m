function [predictedLabelAll,autoFrameIDAll,autoCordXAll,autoCordYAll,ver, autoAreaAll, maxPixelIdxListAll...
    , mouseFrameNum, mouseCenterXY, mouseMasksAll,unifiedPixelIdxListAll] = ReadAutoDetections(imgDir,addAutoToLabel,removeBGdetections,classifierVer,HeuristicVer)
% addAutoToLabel - adds the string "Auto " to the label string
%ver = 'VerSep11_2023'
%ver = 'VerSep11_2023_Epoch77';
%ver = 'VerSep27_2023_Epoch48';
%ver = 'VerSep27_2023_Epoch99';

ver = classifierVer;

predictedLabelAll = {};
autoFrameIDAll = [];
autoCordXAll = [];
autoCordYAll = [];
autoAreaAll = [];
maxPixelIdxListAll = {};
unifiedPixelIdxListAll={};
mouseFrameNum=[];
mouseCenterXY=[];
mouseMasksAll = [];

if nargin < 2
    addAutoToLabel = true;
end
if nargin < 3
    removeBGdetections = true;
end

if addAutoToLabel
    prefix = 'Auto ';    
else
    prefix = '';
end
for k=1:2
    
    autoFrameID = [];
    autoCordX = [];
    autoCordY = [];
            
    if k==1
        autoDetectionHabDir = dir(fullfile(imgDir,['*_Habituation',HeuristicVer]));
    else
        autoDetectionHabDir = dir(fullfile(imgDir,['*_Trial',HeuristicVer]));
    end
    if length(autoDetectionHabDir)>0
        if length(autoDetectionHabDir)>1
            disp(['warning, several detection dirs, taking: ',autoDetectionHabDir(end).name])
        end
        %fname = fullfile(imgDir,autoDetectionHabDir(1).name,'Test_Epoch-1.csv');
        fname = fullfile(imgDir,autoDetectionHabDir(end).name,'Detections.mat');
        if ~exist(fname,'file')
            error(['missing heuristic results mat file:',fname]);
        else
            detections = load(fullfile(imgDir,autoDetectionHabDir(end).name,'Detections.mat'));
            
            mouseCenterXYtmp = zeros(length(detections.mouseMeanTemp(:,1)),2);
            for mmm=1:length(detections.mouseMeanTemp(:,1))
                [i,j] = find(detections.masksAll{mmm,1});
                mouseCenterXYtmp(mmm,:) = [mean(j),mean(i)];
            end
            mouseFrameNum = cat(1,mouseFrameNum,detections.mousePosXYFrame(:,3));
            mouseCenterXY = cat(1,mouseCenterXY,mouseCenterXYtmp);
            mouseMasksAll = cat(1,mouseMasksAll,detections.masksAll);

            oldRegionsVec = detections.oldRegionsVec;
            nDetections = 0;
            detSaved = false(length(oldRegionsVec),1);
            for dd=1:length(oldRegionsVec)
                detSaved(dd) = oldRegionsVec{dd}.regionSaved;                
            end
            oldRegionsVec = oldRegionsVec(detSaved);
            nDetections= length(oldRegionsVec);
            detName = cell(1,length(nDetections));
            for dd=1:length(oldRegionsVec)
                detName{dd} = ['BG_Frame',num2str(oldRegionsVec{dd}.hotFrame,'%.5d'),'_X',num2str(oldRegionsVec{dd}.maxCordJ),'_Y',num2str(oldRegionsVec{dd}.maxCordI)];
            end

            [~,indSort] = sort(detName);
            oldRegionsVec = oldRegionsVec(indSort);
        end
        fname = fullfile(imgDir,autoDetectionHabDir(end).name,['Test_',ver,'_Epoch_-1.csv']);
        if exist(fname,'file')
            s = dir(fname);
            if s.bytes > 0 %not an empty file
                autoResHab = readtable(fname,'delimiter',',');
                name = autoResHab.Var1;
                labels= autoResHab.label;
                detInd = 1:length(labels);
                if length(labels)~=nDetections
                    error('number of events in classifier csv is different from heuristic detections in detecton.mat')
                end
                %remove bg detections:
                if removeBGdetections
                    name = name(labels>0);
                    detInd = detInd(labels>0);
                    labels = labels(labels>0);
                end

                %predictedLabel = autoResHab.label;
                autoFrameID = zeros(length(name),1);
                autoCordX = zeros(length(name),1);
                autoCordY = zeros(length(name),1);
                autoArea = zeros(length(name),1);
                maxPixelIdxList = cell(length(name),1);
                unifiedPixelIdxList = cell(length(name),1);
                for n=1:length(name)
                    tmp = sscanf(name{n},'BG_Frame%d_X%d_Y%d');
                    autoFrameID(n)=tmp(1);
                    autoCordX(n)=tmp(2);
                    autoCordY(n)=tmp(3);

                    extraDetData = oldRegionsVec{detInd(n)};
                    if extraDetData.maxCordI ~= autoCordY(n) || extraDetData.maxCordJ ~= autoCordX(n) || extraDetData.hotFrame ~= autoFrameID(n)
                        error('classifier is not synced with detections.mat');
                    end
                    if isfield(extraDetData,'maxPixelIdxList')
                        autoArea(n) = length(extraDetData.maxPixelIdxList);
                        maxPixelIdxList{n} = extraDetData.maxPixelIdxList;
                    else
                        autoArea(n) = length(extraDetData.PixelIdxList);
                        maxPixelIdxList{n} = extraDetData.PixelIdxList;
                    end
                    if isfield(extraDetData,'unifiedPixelIdxList')
                        unifiedPixelIdxList{n} = extraDetData.unifiedPixelIdxList;
                    else
                        unifiedPixelIdxList{n}=nan;
                    end
                    if     labels(n)==0
                        predictedLabelAll{end+1}=[prefix,'BG'];
                    elseif labels(n)==1
                        predictedLabelAll{end+1}=[prefix,'Urine'];
                    elseif labels(n)==2
                        predictedLabelAll{end+1}=[prefix,'Feces'];
                    elseif labels(n)==3
                        predictedLabelAll{end+1}=[prefix,'Shifted Feces'];
                    else
                        error('invalid label');
                    end
                end
            elseif nDetections~=0
                error(['empty classifier file:',fname]);
            end
        elseif nDetections~=0            
            error(['missing classifier file:',fname]);
        end
    else
        error(['missing heuristic results directory: ',imgDir]);
    end
    
    autoFrameIDAll = [autoFrameIDAll;autoFrameID];
    autoCordXAll = [autoCordXAll;autoCordX];
    autoCordYAll = [autoCordYAll;autoCordY];
    autoAreaAll = [autoAreaAll;autoArea];
    maxPixelIdxListAll = cat(1,maxPixelIdxListAll,maxPixelIdxList);
    unifiedPixelIdxListAll = cat(1,unifiedPixelIdxListAll,unifiedPixelIdxList);
end
predictedLabelAll = predictedLabelAll(:);