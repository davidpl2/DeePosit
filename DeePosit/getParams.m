function params = getParams()

%video params:
params.imRows = 288;
params.imCols = 384;
params.imDtype = 'uint16';
params.fps = 8.663;

params.cmPerPixel = (22-1.2)/143;%0.6 is the wall width
params.LargeDetectionThres = 1/(params.cmPerPixel^2);%64;

%Database creation params: used in RunDeePositOnDB
params.numBGtoCreate = 20;%20 for hab and 20 for trial so total 40 random bg per video.

%params for generating data for NN classification:
%Changing these parameters will require re-training of the classifier!
params.step = 8;
params.pastSteps = 12; 
params.futureSteps = 65;
params.winRad = 32; %classifier gets a video clip of size [winRad*2+1,winRad*2+1, params.pastSteps+params.futureSteps+1]
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

params.HeuristicVer='1.22LowThres';
params.detDir = '..\DeePositDetectionResults\';
params.vidDir = '..\VideoDatabase\';
params.tagDir = params.vidDir;


params.pythonExe = '"C:\ICR Dup\Code\UrineDetectionWithDetr\venv\Scripts\python.exe"';
params.mainScript = '"main.py"';
params.classifierWorkingDir = '.\Classifier\';


params.weightFile = '.\Classifier\TrainedWeights\2024-02-29_18-39-07_checkpoint0229.pth';%put " at begining and end only if using absolute path
params.classifierVer='Ver29Feb24_Db1.20_Epoch229'; %
params.evalOutFilePostfix = params.classifierVer;

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


% to change classifier:
% change past\future steps
% change heuristic version and db folder
% change weights and prefix of classifier.

