function params = getParams()

%video params:
params.imRows = 288;
params.imCols = 384;
params.imDtype = 'uint16';
params.fps = 8.663;

params.cmPerPixel = (22-1.2)/143;%
params.LargeDetectionThres = 1/(params.cmPerPixel^2);%;

params.detDir = '..\DeePositDetectionResults\';
params.vidDir = '..\VideoDatabase\';
params.tagDir = params.vidDir;


params.pythonExe = '"C:\ICR Dup\Code\UrineDetectionWithDetr\venv\Scripts\python.exe"';
params.mainScript = '"main.py"';
params.classifierWorkingDir = '.\Classifier\';


params.weightFile = '.\Classifier\TrainedWeights\2024-11-25_21-18-01_checkpoint0049.pth';%put " at begining and end only if using absolute path
params.classifierVer='Ver25Nov24_Db1.23_Epoch49'; 
params.evalOutFilePostfix = params.classifierVer;

%heuristic detection main parameters:
params.HeuristicVer='1.24HighThres';
params.minDeltaT = 1.6;    %min delta temperature (celsius) for detection
params.cooldownPeriodSec = 40; %after 40 sec of cooldown, the detection should loose 1.1 celsius degrees and at least coolDownFraction of his initial rise
params.minCooldown = 1.1;  %min detection cooldown (celsius) during 40 sec
params.coolDownFraction = 0.5; %the detection should loose at least coolDownFraction of his initial rise
params.minDeltaMouseMask = 1; %threshold (celsius) for detection of the mouse blob
params.minDetectionSize = 2;   %size in pixels
params.maxDetectionSize = 900; %size in pixels
params.minHiddenTime = round(params.fps*30);%new detections in the same place should be atleast 30 sec frames apart
params.minDetectionFrames = 2; % detection should found in atelast 2 frames.
params.minTemp = 10; %min value for a detection (celsius) (values here are chosen such that they do not really affect anything...)
params.maxTemp = 39; %max value for a detection (celsius) (values here are chosen such that they do not really affect anything...)


%Database creation params: used in RunDeePositOnDB
params.numBGtoCreate = 20;%20 for hab and 20 for trial so total 40 random bg per video.

%params for generating data for NN classification:
%Changing these parameters will require re-training of the classifier!
params.step = 8;
params.pastSteps = 12; 
params.futureSteps = 65;
params.winRad = 32; %classifier gets a video clip of size [winRad*2+1,winRad*2+1, params.pastSteps+params.futureSteps+1]
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%for display and analysis graph generation:
params.bgColor = [0,0,255];
params.urineColor = [247,99,0];
params.fecesColor = [185,122,87];
params.ignoreLastXSec = true; %ignore the last params.step*params.futureSteps frames of habituation and trial videos. during graph generation.

params.minTfor8u = 15; %15 Degrees celsius will match gray level 0 in the output avi
params.maxTfor8u = 40.5;%40.5 Degrees celsius will match gray level 255 in the output avi ( so each gray scale is 0.1 Deg Celsius).

params.WTMaleColor = [0,0,1];%blue
params.DupMaleColor = [0,1,1];%cyan
params.WTFemaleColor = [1,0,0];%red
params.DupFemaleColor = [1,0,1];%cyan



