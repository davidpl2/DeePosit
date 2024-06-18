%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%RunDeePosit on database
%   The script can do several operations:
%   1. Run the prelimnary detection + the classifier on the videos in the database
%   to do that, set below:
%       doDetection=true, GenerateDbForClassification=true, runNN=true
%       *setting allowSkip=true will result skipping videos which were
%       already analyzed. (useful when adding new videos to the DB).
%
%   2. Generate the train\test database for training the classifier.
%       to do that, set below: GenerateTrainTestDB = true
%  
%Note that:
% 1.the link to the database folder should be written in getParams.m
% 2.the link to python.exe inside the relevant virtual environment should
% be set correctly in getParams()
% 3. the output folder can be changed in getParams(). otherwise it will be: ..\DeePositDetectionResults\ 
% 4. The script will run only on videos in which the basic tagging was done ( the area of the arena's floor was marked as well as the range of frames of habituation and trial were specified).  
%
%Code Author: David Peles, Shlomo Wagner's Lab, University of Haifa.
%This code is an implementation of the paper: Peles et al, DeePosit: an AI-based tool for detecting mouse urine and fecal depositions from thermal video clips of behavioral experiments
%
clear all;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%preliminary detection:
doDetection = true; % if true, runs the preliminary detection.
allowSkip = true; %skip preliminary detection if the detection results exist for this video

%running the classifier:
GenerateDbForClassification = true;
runNN = true; % if true, runs the classifier. (GenerateDbForClassification should also be true).

%generating train\test db:
GenerateTrainTestDB = false; % if true, generates training and testing database for the classifier

%clean-up
doCleanUp = true; %erase temporary files before starting and after finishing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

params = getParams();
HeuristicVer = params.HeuristicVer;
classifierVer=params.classifierVer;
outputDir = params.detDir;

RGBResPathTrain = [outputDir,'\HeuristicResPath_',HeuristicVer,'\'];
RGBResPathTest  = [outputDir,'\HeuristicResPath_',HeuristicVer,'\'];
trainDbOutdir = [outputDir,'\DB_Train_',HeuristicVer,'\'];
testDbOutDir  = [outputDir,'\DB_Test_',HeuristicVer,'\'];
if doCleanUp
    try
        if exist(RGBResPathTrain,'dir')
            rmdir(RGBResPathTrain,'s');
        end
        if exist(RGBResPathTest,'dir')
            rmdir(RGBResPathTest,'s');
        end
    end
end
if GenerateDbForClassification
    mkdir(RGBResPathTrain)
    mkdir(RGBResPathTest)
end

if GenerateTrainTestDB
    mkdir(trainDbOutdir)
    mkdir(testDbOutDir)
end


[dirList,vidsTable,vidType, baseDir, isMale, isWT] = GetVidsList(params.vidDir);

usedVis = find(vidsTable.bbAndCageTaggingDone);


disp(params.classifierVer)
trainVids = find(vidsTable.isTrain);
taggedTestVids = find(vidsTable.isTest);

%params for generating data for NN classification:
numBGtoCreate = params.numBGtoCreate;%20 for hab and 20 for trial so total 40 random bg per video.
%params for generating data for NN classification:
step = params.step;% was 9
pastSteps = params.pastSteps;
futureSteps = params.futureSteps;
%%%%%%%%%%%%%%%%%%

curDateStr = datestr(now,'yyyy-mm-dd_HH-MM-SS');

logFile = fopen(fullfile(outputDir,['RunDeePositOnDB_Log_',curDateStr,'.txt']),'wt');
%usedVis = [142]
for vidIndexI = 1:length(usedVis)% vidIndexI=150,151 had an issue

    vidIndex = usedVis(vidIndexI);
    vidId   = usedVis(vidIndexI);
    isTaggedTest = ismember(vidId, taggedTestVids);
    isTrain = ismember(vidId, trainVids);
    disp(['Vid Id = ',num2str(vidIndex)])
    fprintf(logFile,['video id: ',num2str(vidIndex),'\n']);

    srcDir00 = fullfile(params.vidDir,dirList{vidIndex});
    if ~isempty(strfind(lower(srcDir00),'notvalid'))
        continue;
    end

    curDoDetection = doDetection;
    detectionWasDone = false;
    vidOutputDir = fullfile(outputDir,dirList{vidIndex});

    
    %skip this video if it was already processed:
    if ~GenerateTrainTestDB %if we generate train and test DB than we wont skip videos.
        dirListHab = dir(fullfile(vidOutputDir,['*Habituation',HeuristicVer]));
        dirList0 = dir(fullfile(vidOutputDir,['*Trial',HeuristicVer]));
        detectionWasDone = false;
        if (length(dirList0)>0) && (length(dirListHab)>0)
            classifierFnameHab = fullfile(vidOutputDir,dirListHab(end).name,['Test_',classifierVer,'_Epoch_-1.csv']);
            classifierFnameTrial = fullfile(vidOutputDir,dirList0(end).name,['Test_',classifierVer,'_Epoch_-1.csv']);

            detectionWasDone = exist(fullfile(vidOutputDir,dirListHab(end).name,'Detections.mat')) &&...
                exist(fullfile(vidOutputDir,dirList0(  end).name,'Detections.mat'));

            
            if detectionWasDone
                nDetectionsHab = GetNumDetections(fullfile(vidOutputDir,dirListHab(end).name,'Detections.mat'));
                nDetectionsTrial = GetNumDetections(fullfile(vidOutputDir,dirList0(end).name,'Detections.mat'));

                detFileHab = dir(fullfile(vidOutputDir,dirListHab(end).name,'Detections.mat'));
                detFileTrial = dir(fullfile(vidOutputDir,dirList0(end).name,'Detections.mat'));

                detectionDate = min(datetime(detFileHab.date),datetime(detFileTrial.date));

                if (exist(classifierFnameHab)||(nDetectionsHab==0)) &&...
                        (exist(classifierFnameTrial)||(nDetectionsTrial==0))

                    taggingDate = dir(fullfile(srcDir00,'BBandCageContours.xml'));
                    disp(['taggind date=',taggingDate.date])
                    taggingDate = datetime(taggingDate.date);

                    %detectionDate = min(datetime(dirListHab(end).date),datetime(dirList0(end).date));
                    disp(['detection date=',string(detectionDate)])
                    if (detectionDate>taggingDate)
                        disp(['detection done after last tagging'])
                        curDoDetection = false;
                        if ~GenerateTrainTestDB
                            if allowSkip
                                disp(['Skipping Vid Id = ',num2str(vidIndex)])
                                continue;
                            end
                        end
                    else
                        detectionWasDone = false;
                        disp(['detection is not up to date']);
                        fprintf(logFile,['detection is not up to date:', srcDir00,'\n']);

                    end
                end
            end
        end
    end

    
    if ~(doDetection || GenerateDbForClassification || GenerateTrainTestDB)
        GetImageListAndNucIm = false; %reduce run time if listing the images in the folder is not needed
    else
        GetImageListAndNucIm = true;
    end

    [srcDir,parts,imgsList,imgNUC,handles] = GetVidParts(vidIndex,[],[],params.vidDir,GetImageListAndNucIm);
    if ~exist(srcDir,'dir')
        disp(['Missing Folder', srcDir,'Skipping Vid Id = ',num2str(vidIndex)]);
        fprintf(logFile,['Missing Folder', srcDir,'Skipping Vid Id = ',num2str(vidIndex),'\n']);
        continue;
    end
    

    fprintf(logFile,['video dir: ',srcDir,'\n']);
    if isfield(handles,'clickX') %the video have annotations of urine\feces
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

    %Loading video to memory. the video will be loaded into the variable: global IrImgVec
    if curDoDetection || GenerateDbForClassification || GenerateTrainTestDB
        fprintf(logFile,'Loading video\n');
        LoadVideoToMem2(srcDir,imgsList,imgNUC,handles);
    end

    [~,vidName,~] = fileparts(srcDir);
    habFrames = handles.habFrames;
    trialFrames = handles.trialFrames;

    if ~ismember(vidIndex,trainVids)
        RGBResPath = RGBResPathTest;
    else
        RGBResPath = RGBResPathTrain;
    end

    for t=1:2
        if t==1
            %Habituation Analysis:
            cageMask = handles.habCageMask;
            startI = handles.habFrames(1);
            endI = handles.habFrames(2);
            outDirPostfix = '_Habituation';
            rgbDIR = fullfile(RGBResPath,[vidName,'_Hab']);
            fprintf(logFile,['Processing Habituation. rgbDir=',rgbDIR,'\n']);
        elseif t==2
            %Trial Analysis:
            cageMask = handles.trialCageMask;
            startI = handles.trialFrames(1);
            endI = handles.trialFrames(2);
            outDirPostfix = '_Trial';
            rgbDIR = fullfile(RGBResPath,[vidName,'_Trial']);
            fprintf(logFile,['Processing Trial. rgbDir=',rgbDIR,'\n']);
        end
        disp('Running Detection');
        if curDoDetection && (~detectionWasDone)            
            fprintf(logFile,'DetectUrineAndFecesLowThreshold\n');            
            curOutPath = DetectUrineAndFecesLowThreshold22(startI,endI,~cageMask,imgsList,srcDir,outDirPostfix,habFrames,trialFrames,vidOutputDir);
        else
            if t==1
                dirList0 = dir(fullfile(vidOutputDir,['*Habituation',HeuristicVer]));
            else
                dirList0 = dir(fullfile(vidOutputDir,['*Trial',HeuristicVer]));
            end
            curOutPath = fullfile(vidOutputDir,dirList0(end).name);
            fprintf(logFile,['Using previous detections for classification: ',dirList0(end).name,'\n']);
        end
        if GenerateDbForClassification
            disp('Generating Data for Classification');
            fprintf(logFile,'Generating Data for Classification\n');
            [nDetections,detCordX,detCordY,detFrame,detType,detPixels] = GenerateDataForClassification(curOutPath,rgbDIR, step,pastSteps,futureSteps);
        else
            det = load(fullfile(curOutPath,'Detections.mat'));
            detCordX = [];
            detCordY = [];
            detFrame = [];
            detPixels = {};
            for r=1:length(det.oldRegionsVec)
                if ~det.oldRegionsVec{r}.regionSaved
                    continue
                end
                detCordY(end+1) = det.oldRegionsVec{r}.maxCordI;
                detCordX(end+1) = det.oldRegionsVec{r}.maxCordJ;
                detFrame(end+1) = det.oldRegionsVec{r}.hotFrame;%firstFrameInd;
                detPixels{end+1} = det.oldRegionsVec{r}.PixelIdxList;
            end
            detType=repmat({'BG'},size(detCordX));
            nDetections = length(detCordX);
        end
        if runNN
            classifierResFname = fullfile(curOutPath,['Test_',classifierVer,'_Epoch_-1.csv']);
            if nDetections>0
                if ~exist(classifierResFname,'file') || ~allowSkip
                    fprintf(logFile,'Running Classifier\n');
                    RunDeePositClassifier(rgbDIR,curOutPath);                    
                else
                    fprintf(logFile,'Classifier Res already exist\n');
                end
            else
                disp('no detections so deleting classifier old res')
                delete(classifierResFname);
            end
        end

        if GenerateTrainTestDB && (ismember(vidId,taggedTestVids) || ismember(vidId,trainVids))

            disp('Generating Data for training\validation');
            fprintf(logFile,'Generating Data for training and validation\n');
            if ~isTrain
                %for test detections, output is without +-2 pixel
                %augmenataion and without time +-3sec time augmentation
                outDir = testDbOutDir;
                timeAugmentation = false;
            else
                outDir = trainDbOutdir;
                timeAugmentation = true;
            end
            vidLoadedToMem = true;

            %generate manual points:
            if t==1 %do this only once...
                %generate images for ground truth:
                disp('Generating Data for training - manual points');
                fprintf(logFile,'Generating Data for training - manual points\n');
                %timeAugmentation and +-2pixel augmentation if this is a train vid.
                GenerateDatabaseSingleVid(vidIndex, outDir, gtCordX, gtCordY, gtFrame, gtType, timeAugmentation,~isTrain,vidLoadedToMem,step,pastSteps,futureSteps);
                if numBGtoCreate>0
                    %generate images for random background:
                    disp('Generating Data for training - random points');
                    fprintf(logFile,['Generating Data for training - random points, numBGtoCreate=',num2str(numBGtoCreate),'\n']);
                    [bgCordXH,bgCordYH,bgTypeH,bgFrameH] = GetBGRandCords(handles.habCageMask, habFrames, numBGtoCreate);
                    [bgCordXT,bgCordYT,bgTypeT,bgFrameT] = GetBGRandCords(handles.trialCageMask, trialFrames, numBGtoCreate);
                    %random bg is without time augmentation.
                    GenerateDatabaseSingleVid(vidIndex, outDir, bgCordXH, bgCordYH, bgFrameH, bgTypeH, false,~isTrain,vidLoadedToMem,step,pastSteps,futureSteps);
                    GenerateDatabaseSingleVid(vidIndex, outDir, bgCordXT, bgCordYT, bgFrameT, bgTypeT, false,~isTrain,vidLoadedToMem,step,pastSteps,futureSteps);
                end
            end

            isFalseDet = false(size(detCordX));
            for f=1:length(detFrame)
                isFalseDet(f) = isFalseDetection(detCordX(f),detCordY(f),detFrame(f),detPixels{f},gtCordX,gtCordY,gtFrame);
            end

            %generate images for hard examples from heuristic results:
            disp('Generating hard examples');
            fprintf(logFile,'Generating hard examples\n');
            %timeAugmentation and +-2pixel augmentation if this is a train vid.
            GenerateDatabaseSingleVid(vidIndex, outDir, detCordX(isFalseDet), detCordY(isFalseDet), detFrame(isFalseDet), detType(isFalseDet), timeAugmentation, ~isTrain, vidLoadedToMem,step,pastSteps,futureSteps);
        end
    end

    [predictedLabel,hotFrameI,xCord,yCord,ver, areaPixels, maxPixelIdxListAll,...
     mouseFrameNum, mouseCenterXY, mouseMasksAll,unifiedPixelIdxListAll] = ReadAutoDetections(vidOutputDir,false,false,params.classifierVer,params.HeuristicVer);

    T = table(hotFrameI,predictedLabel,xCord,yCord,areaPixels);
    writetable(T,fullfile(vidOutputDir,'DeePositRes.csv'));

    %catch me
    %    fprintf(logFile,['Exception, processing of video was not finished. video id: ',num2str(vidIndex),'\n'])
    %end
end

fprintf(logFile,'Finished');
fclose(logFile)

if doCleanUp
    try
        if exist(RGBResPathTrain,'dir')
            rmdir(RGBResPathTrain,'s');
        end
        if exist(RGBResPathTest,'dir')
            rmdir(RGBResPathTest,'s');
        end
    end
end

disp('Finished')
