%Author David Peles
function varargout = DeePositLabeler(varargin)
% DEEPOSITLABELER MATLAB code for DeePositLabeler.fig
%      DEEPOSITLABELER, by itself, creates a new DEEPOSITLABELER or raises the existing
%      singleton*.
%
%      H = DEEPOSITLABELER returns the handle to a new DEEPOSITLABELER or the handle to
%      the existing singleton*  .
%
%      DEEPOSITLABELER('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in DEEPOSITLABELER.M with the given input arguments.
%
%      DEEPOSITLABELER('Property','Value',...) creates a new DEEPOSITLABELER or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before DeePositLabeler_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to DeePositLabeler_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help DeePositLabeler

% Last Modified by GUIDE v2.5 17-Jun-2024 11:20:25

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @DeePositLabeler_OpeningFcn, ...
    'gui_OutputFcn',  @DeePositLabeler_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before DeePositLabeler is made visible.
function DeePositLabeler_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to DeePositLabeler (see VARARGIN)

% Choose default command line output for DeePositLabeler
handles.output = hObject;
handles.contInd = 1;
handles.needToSave=false;
% Update handles structure
guidata(hObject, handles);

% UIWAIT makes DeePositLabeler wait for user response (see UIRESUME)
% uiwait(handles.figure1);

function handles = updateRoisList(handles)

clickX = handles.clickX;
clickY = handles.clickY;
clickFrame = handles.clickFrame;
clickType = handles.clickType;

[~,sortInd] = sort(clickFrame,'ascend');
clickX = clickX(sortInd);
clickY = clickY(sortInd);
clickFrame = clickFrame(sortInd);
clickType = clickType(sortInd);

handles.clickX = clickX;
handles.clickY = clickY;
handles.clickFrame = clickFrame;
handles.clickType = clickType;

strAr={};
for k=1:length(clickX)
    strAr{k} = ['#',num2str(k),', ', clickType{k} ,', Frame:', num2str(clickFrame(k)) ];
end
set(handles.roisList,'String',strAr);
set(handles.roisList,'Value',length(strAr));
handles.needToSave = true;

% --- Outputs from this function are returned to the command line.
function varargout = DeePositLabeler_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in loadBn.
function loadBn_Callback(hObject, eventdata, handles, selectedVidDir)
% hObject    handle to loadBn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if isfield(handles,'needToSave')
    if handles.needToSave
        opts.Default = 'Cancel';
        opts.Interpreter = 'none';
        answer = questdlg('Save Before Continue?','Last changes were not saved',...
            'Yes','No','Cancel',opts);
        if strcmp(answer,'Cancel')
            return;
        elseif strcmp(answer,'Yes')
            handles = saveBn_Callback(hObject, eventdata, handles);
        end
    end
end


if exist('selectedVidDir','var')
    handles.imgDir = makeAbsPath(selectedVidDir);
    handles.fileEnd='.bin';
else
    if isfield(handles,'imgDir')
        startDir = handles.imgDir;
    else        
        startDir = 'C:\';
    end
    [file,handles.imgDir] = uigetfile({'*.bin;*.tif','images'},'Select an image File',startDir);
    if isequal(handles.imgDir,0)
        return;
    end
    [~,~,handles.fileEnd] = fileparts(file);
end
global imgVecAvailable;
imgVecAvailable = false;
handles.fps = 8.663;
handles.logText.String ='';
% if exist(fullfile(handles.imgDir,'imgList.mat'),'file')
%     disp('loading image list from mat file'),tic();
%     handles.imgList = load(fullfile(handles.imgDir,'imgList.mat'));
%     handles.imgList = handles.imgList.imgList;
%     disp(['listing images done time =',num2str(toc())]);
% else
disp('listing images (dir)'),tic();
handles.imgsList= dir(fullfile(handles.imgDir,['*',handles.fileEnd]));
disp(['listing images done time(sec) =',num2str(toc())]);
imgList = handles.imgsList;
%    save(fullfile(handles.imgDir,'imgList.mat'),'imgList');
%end

isNucIm = false(length(handles.imgsList),1);
for k=1:length(handles.imgsList)
    isNucIm(k) = isequal(handles.imgsList(k).name(1:3),'NUC');
end
handles.imgsList = handles.imgsList(~isNucIm);

imgId = getImgId(handles.imgsList);
[~,ind] = sort(imgId,'ascend');
handles.imgsList = handles.imgsList(ind);


%[file,path] = uigetfile({'NUC*.bin','NUC image'},'Select a NUC File');
fnames = dir(fullfile(handles.imgDir,'NUC*.bin'));
if length(fnames)==1
    handles.nucFname = fullfile(handles.imgDir,fnames(1).name);
    disp(['using Nuc file: ',handles.nucFname])
else
    [nucFile,pathNuc] = uigetfile(fullfile(handles.imgDir,'NUC*.bin'),'Select a NUC File');
    handles.nucFname = fullfile(pathNuc,nucFile);
end
rows = 288;
cols = 384;
handles.imgNUC = bImread(handles.nucFname,rows,cols,'float32');
handles.imgNUC = handles.imgNUC-mean(handles.imgNUC(:));


handles.curImgI = 1;
set(handles.framesSlider,'Min',1);
set(handles.framesSlider,'Max',length(handles.imgsList));
set(handles.framesSlider,'Value',1);
set(handles.framesSlider,'SliderStep',[1/length(handles.imgsList), (handles.fps*60) /length(handles.imgsList)]);

%handles.cageX = [];
%handles.bbX =[];

handles.habCageX = [];
handles.habCageY = [];
handles.trialCageX = [];
handles.trialCageY = [];

handles.habBbX =[];
handles.habBbY =[];
handles.trialBbX =[];
handles.trialBbY =[];

handles.habBbMask = [];
handles.trialBbMask = [];
handles.trialCageMask=[];
handles.habCageMask=[];


%handles.contInd = 1;
set(handles.contrastText,'String',['C',num2str(handles.contInd)]);

%handles.minMaxDeg = [20,30;15,45; 30,40; 16, 25; 10,60;5,30;-1,-1];
handles.minMaxDeg = [0,0; 0,0; 0,0; 0,0;0,0; -1,-1];
handles.clickX = [];
handles.clickY = [];
handles.clickType = {};
handles.clickFrame = [];

handles.stim1Line = [];
handles.stim2Line = [];

set(handles.habituationFramesStart,'String','0');
set(handles.habituationFramesEnd,'String','0');

set(handles.trialStartFrames,'String','0');
set(handles.trialEndFrames,'String','0');

set(handles.roisList,'String',{});

%handles.urineLabel = 1;
%handles.fecesLabel = 2;
%handles.shitedFecesLabel = 3;
%handles.labelName = {'U','F','SF'};
handles.tagFinished.Value = 0;
BBandCageContours = fullfile(handles.imgDir,'BBandCageContours.xml');
if ~exist(BBandCageContours,'file')
    BBandCageContours = fullfile(handles.imgDir,'BBandCageContoursAuto.xml');
end

if exist(BBandCageContours,'file')
    s = readstruct(BBandCageContours);
    if isfield(s.habCage,'habCageX')
        handles.habCageX = s.habCage.habCageX;
        handles.habCageY = s.habCage.habCageY;
        handles.habCageMask = roipoly(zeros(rows,cols),handles.habCageX,handles.habCageY);
    end

    if isfield(s.trialCage,'trialCageX')
        handles.trialCageX = s.trialCage.trialCageX;
        handles.trialCageY = s.trialCage.trialCageY;
        handles.trialCageMask = roipoly(zeros(rows,cols),handles.trialCageX,handles.trialCageY);
    end

    if isfield(s.habBB,'habBbX')
        handles.habBbX = s.habBB.habBbX;
        handles.habBbY = s.habBB.habBbY;
        handles.habBbMask = roipoly(zeros(rows,cols),handles.habBbX,handles.habBbY);
    end
    if isfield(s.trialBB,'trialBbX')
        handles.trialBbX = s.trialBB.trialBbX;
        handles.trialBbY = s.trialBB.trialBbY;
        handles.trialBbMask = roipoly(zeros(rows,cols),handles.trialBbX,handles.trialBbY);
    end

    if isfield(s,'stim1LineX')
        handles.stim1Line = [s.stim1LineX(:),s.stim1LineY(:)];
    end
    if isfield(s,'stim2LineX')
        handles.stim2Line = [s.stim2LineX(:),s.stim2LineY(:)];
    end
    if isfield(s,'habFrames')
        set(handles.habituationFramesStart,'String',num2str(s.habFrames.habStartFrame));
        set(handles.habituationFramesEnd,'String',num2str(s.habFrames.habEndFrame));
    end

    if isfield(s,'trialFrames')
        set(handles.trialStartFrames,'String',num2str(s.trialFrames.trialStartFrame));
        set(handles.trialEndFrames,'String',num2str(s.trialFrames.trialEndFrame));
    end

    if isfield(s,'tagFinished')
        handles.tagFinished.Value=s.tagFinished;
    end
end

GT_DetectionsFile = fullfile(handles.imgDir,'GT_Detections.xlsx');
if exist(GT_DetectionsFile,'file')
    T = readtable(GT_DetectionsFile);
    handles.clickX = T.x;
    handles.clickY = T.y;
    handles.clickFrame = T.frameIndex;
    handles.clickType = T.type;
    handles = updateRoisList(handles);
end
params = getParams();
if 1 
    [vidId,isTest,handles.vidData] = GetVidId(handles.imgDir,params.vidDir);
    if ~isempty(vidId)
        AddToLog(handles,['VidId=',num2str(vidId), ' isTestVid=',num2str(isTest)]);
    else
        AddToLog(handles,['VidId not defined']);
    end
else
    handles.vidData = [];    
end

global doLoadDetections
if doLoadDetections
    %classifierVer='Ver03Oct23_Db1.13_Epoch99';
    params = getParams();
    if 0 
        classifierVer='Ver25Nov23_Db1.16_Epoch29';
        HeuristicVer='1.18LowThres';
    else
        classifierVer='Ver08Feb24_Db1.19_Epoch109';
        HeuristicVer='1.19LowThres';
    end
    classifierVer=params.classifierVer;
    HeuristicVer=params.HeuristicVer;

    AddToLog(handles,'Reading Auto Detections with versions:')
    AddToLog(handles,['HeuristicVer: ',HeuristicVer])
    AddToLog(handles,['classifierVer: ',classifierVer])
    dirAtE = replace(handles.imgDir,params.vidDir,params.detDir);
    [predictedLabelAll,autoFrameIDAll,autoCordXAll,autoCordYAll,ver] = ReadAutoDetections(dirAtE,true,false,classifierVer,HeuristicVer);
    detHab =[];
    detTrial = [];
    handles.maskMouseCloseVec=[];
    handles.detFrames = [];
    handles.detMax =[];
    handles.detMed = [];    
else
    predictedLabelAll=[];
    handles.maskMouseCloseVec = {};
    handles.detFrames = [];
end


if length(predictedLabelAll)>0
    handles.clickType = [handles.clickType; predictedLabelAll];
    handles.clickX = [handles.clickX;autoCordXAll];
    handles.clickY = [handles.clickY;autoCordYAll];
    handles.clickFrame = [handles.clickFrame;autoFrameIDAll];
    handles = updateRoisList(handles);
end



handles.needToSave = false;
handles.maxIm = zeros(rows,cols);

handles = UpdateDisplay(hObject,handles);
guidata(hObject,handles);






%
% function CalcGraphsForRois(handles)
% rows = 288;
% cols = 384;
% global IrImgVec
% global imgVecAvailable;
% if ~imgVecAvailable
%     return;
% end
% I = zeros(rows,cols);
% [X,Y] = meshgrid(1:cols,1:rows);
% graphs = zeros(251,length(handles.GTSegList));
% type = zeros(251,length(handles.GTSegList));
% for k=1:length(handles.GTSegList)
%     curSeg = handles.GTSegList(k);
%
%     frameInd = curSeg.frameInd;
%     curIm = IrImgVec(:,:,curSeg.frameInd);
%     BW = roipoly(I,curSeg.x,curSeg.y);
%     ind = find(BW);
%     [~,maxInd2] = max(curIm(ind));
%     [maxIndI,maxIndJ] = ind2sub(size(I),ind(maxInd2));
%     type(k) = curSeg.label;
%     graphs(:,k) = squeeze(IrImgVec(maxIndI,maxIndJ,frameInd-50:frameInd+200));
% end
% [foundFeces, fecesThatWasMoved, medCoolRatio] = isFecesGraph(graphs);
%
%
% axes(handles.graphAxis),hold off,
% if 1
%     roisSelected = get(handles.roisList,'Value');
%     if type(roisSelected) ==handles.fecesLabel
%         color='r';
%     elseif type(roisSelected) ==handles.shitedFecesLabel
%         color = 'm';
%     else
%         color = 'g';
%     end
%     plot(graphs(:,roisSelected),color),hold on
% else
%     plot(graphs(:,type==handles.fecesLabel),'r'),hold on
%     plot(graphs(:,type==handles.urineLabel),'g');
%     startX = ((1:length(handles.GTSegList)) - 0.5) * 251/max(1,length(handles.GTSegList));
%     startX = round(startX);
%     for k=1:length(handles.GTSegList)
%         text(startX(k),graphs(startX(k),k),num2str(k));
%     end
% end
%
% grid minor

function play(hObject, handles, skip)

set(handles.stopBn,'Value',1);
enabled = true;
while enabled
    if handles.curImgI<length(handles.imgsList)
        handles.curImgI = min(length(handles.imgsList), handles.curImgI+skip);
        handles = UpdateDisplay(hObject,handles);
    else
        break;
    end
    pause(0.0001);
    drawnow
    enabled = get(handles.stopBn,'Value');
end
guidata(hObject,handles);
set(handles.stopBn,'Value',0);

% --- Executes on button press in playBn.
function playBn_Callback(hObject, eventdata, handles)
% hObject    handle to playBn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if get(handles.stopBn,'Value')
    set(handles.stopBn,'Value',0)%pause
else
    play(hObject, handles, 1);
end



% --- Executes on button press in playX5Bn.
function playX5Bn_Callback(hObject, eventdata, handles)
% hObject    handle to playX5Bn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if get(handles.stopBn,'Value')
    set(handles.stopBn,'Value',0)%pause
else
    play(hObject, handles, 10);
end

% set(handles.playBn,'Value',1);
% enabled = true;
% while enabled
%     if handles.curImgI<length(handles.imgsList)
%         handles.curImgI = handles.curImgI+1;
%         handles = UpdateDisplay(hObject,handles);
%         pause(0.0001);
%         drawnow
%     else
%         break;
%     end
%     enabled = get(handles.playBn,'Value');
% end
% guidata(hObject,handles);



function handles = UpdateDisplay(hObject,handles, openNewFig)

if nargin <3
    openNewFig= false;
end
curFname = fullfile(handles.imgDir,handles.imgsList(handles.curImgI).name);
[p,name,ext] = fileparts(curFname);

habStart = str2num(get(handles.habituationFramesStart,'String'));
habEnd = str2num(get(handles.habituationFramesEnd,'String'));

trialStart = str2num(get(handles.trialStartFrames,'String'));
trialEnd = str2num(get(handles.trialEndFrames,'String'));


if (handles.curImgI>=habStart)&&(handles.curImgI<=habEnd)
    cageX = handles.habCageX;
    cageY = handles.habCageY;
    bbX = handles.habBbX;
    bbY = handles.habBbY;
    bbMask = handles.habBbMask;
elseif (handles.curImgI>=trialStart)&&(handles.curImgI<=trialEnd)
    cageX = handles.trialCageX;
    cageY = handles.trialCageY;
    bbX = handles.trialBbX;
    bbY = handles.trialBbY;
    bbMask = handles.trialBbMask;
else
    cageX = [];
    cageY = [];
    bbX = [];
    bbY = [];
    bbMask = [];
end

if isequal(ext,'.bin')
    rows = 288;
    cols = 384;
    dtype = 'uint16';

    global IrImgVec;
    global imgVecAvailable;
    if imgVecAvailable
        handles.imC = IrImgVec(:,:,handles.curImgI);
    else
        handles.curIm = bImread(curFname,rows,cols,dtype,0);
        handles.curIm = single(handles.curIm) - handles.imgNUC;
        handles.imC = (handles.curIm - 27315.0)/100.0;%celsius
        if length(bbX)>0
            meanBB = mean(handles.imC(bbMask));
            handles.imC = handles.imC-meanBB + 37;
        end
    end
    %meanBB = mean2(imC(bbTL(2):bbBR(2),bbTL(1):bbBR(1)));
    %imgEmpty = imC-meanBB + 37;
else
    handles.curIm = imread(curFname);
end
if openNewFig
    figure();
else
    axes(handles.axes1);
end

hold off,

minMaxDeg = handles.minMaxDeg(handles.contInd,:);
%if minMaxDeg(1)>=0
%    handles.imgHandle = imshow(handles.imC,minMaxDeg);
if get(handles.showMaxIm,'Value')
    imC = max(handles.imC,handles.maxIm);
    handles.maxIm = imC;
else
    imC = handles.imC;
end
gamma = get(handles.gammaSlider,'Value');
if handles.contInd==1%linear histogram, impixelinfo is valid.
    maxC = max(imC(:));
    lowhigh = stretchlim(imC/maxC,[0.005,0.995]);
    lowhigh = lowhigh*maxC;
    Drange = lowhigh(2)-lowhigh(1);
    lowhigh(1) = lowhigh(1)-Drange*0.08;
    lowhigh(2) = lowhigh(2)+Drange*0.01;
    handles.imgHandle = imshow(imC,lowhigh);
elseif handles.contInd==2 % max and min, impixelinfo is valid.
    handles.imgHandle = imshow(imC,[]);
elseif handles.contInd==3 % max and min with gamma = 0.5
    imTmp = imC-min(imC(:));
    imTmp = imTmp./max(imTmp(:));
    imTmp = imTmp.^gamma;
    handles.imgHandle = imshow(imTmp,[]);
elseif handles.contInd==4 % %linear histogram, with gamma = 0.5
    imTmp = imC-min(imC(:));
    imTmp = imTmp./max(imTmp(:));
    lowhigh = stretchlim(imTmp,[0.005,0.995]);
    Drange = lowhigh(2)-lowhigh(1);
    lowhigh(1) = lowhigh(1)-Drange*0.08;
    lowhigh(2) = lowhigh(2)+Drange*0.01;
    imTmp = max(0,(imTmp-lowhigh(1)) ./ (lowhigh(2)-lowhigh(1))).^gamma;
    handles.imgHandle = imshow(imTmp,[0,1]);
elseif handles.contInd==5 % histogram equalization
    imTmp = imC-min(imC(:));
    imTmp = imTmp./max(imTmp(:));
    imTmp = histeq(imTmp).^gamma;
    handles.imgHandle = imshow(imTmp,[0,1]);
else %local histogram equalization.
    imTmp = imC - min(imC(:));
    handles.imgHandle = imshow(adapthisteq(imTmp./max(imTmp(:)),'NumTiles',[6 8],'ClipLimit',0.5),[]);
end
if handles.rotate180.Value
    set(handles.axes1,'CameraUpVector',[0,1,0])
else
    set(handles.axes1,'CameraUpVector',[0,-1,0])
end
drawMarks = ~get(handles.hideTaggingCheckbox,'Value');
%drawMarks = true;
if drawMarks
    if length(handles.habCageX)>0
        hold on,h = plot(handles.habCageX,handles.habCageY,'b');
        set(h,'ButtonDownFcn',{@imgClickCallback,hObject});
    end
    if length(handles.trialCageX)>0
        hold on,h=plot(handles.trialCageX,handles.trialCageY,'--c');
        set(h,'ButtonDownFcn',{@imgClickCallback,hObject});
    end
    if length(handles.habBbX)>0
        hold on,h=plot(handles.habBbX,handles.habBbY,'r','LineWidth',2);
        set(h,'ButtonDownFcn',{@imgClickCallback,hObject});
    end
    if length(handles.trialBbX)>0
        hold on,h=plot(handles.trialBbX,handles.trialBbY,'--g','LineWidth',2);
        set(h,'ButtonDownFcn',{@imgClickCallback,hObject});
    end

    if ~isempty(handles.stim1Line)
        hold on,h=plot(handles.stim1Line(:,1),handles.stim1Line(:,2),'g');
        set(h,'ButtonDownFcn',{@imgClickCallback,hObject});
    end
    if ~isempty(handles.stim2Line)
        hold on,h=plot(handles.stim2Line(:,1),handles.stim2Line(:,2),'r');
        set(h,'ButtonDownFcn',{@imgClickCallback,hObject});
    end

    if ismember(handles.curImgI,handles.detFrames)
        ind = find(handles.curImgI==handles.detFrames);
        if length(ind)~=1
            error('something went wrong')
        end
        maskMouse = full(handles.maskMouseCloseVec{ind});
        maskInd = find(maskMouse);
        B = bwboundaries(full(maskMouse));
        hold on,h=plot(B{1}(:,2),B{1}(:,1),'g');
        set(h,'ButtonDownFcn',{@imgClickCallback,hObject});
        grayVals = handles.imC(maskMouse);
        [maxMouse,maxInd] = max(grayVals(:));
        maxInd = maskInd(maxInd);
        [maxRow,maxCol] = ind2sub(size(handles.imC),maxInd);
        plot(maxCol,maxRow,'+r');
        meanMouse = mean(grayVals(:));
        medMouse = median(grayVals(:));

        hold on,text(10,50,['Mouse Max=',num2str(maxMouse,'%.1f')],'Color','green');
        hold on,text(10,10,['Mouse Mean=',num2str(meanMouse,'%.1f')],'Color','green');
        hold on,text(10,30,['Mouse Median=',num2str(medMouse,'%.1f')],'Color','green');



        a = gca();
        axes(handles.mouseTempAxes)
        hold on
        plot(handles.curImgI,maxMouse,'.r')
        plot(handles.curImgI,meanMouse,'.g')
        plot(handles.curImgI,medMouse,'.b')
        xlim([1,length(handles.imgsList)]);
        axes(a);
    end
end

set(handles.imgHandle,'ButtonDownFcn',{@imgClickCallback,hObject});

if ~isempty(handles.clickX) && drawMarks
    showAll = get(handles.showAllSeg,'Value');
    for k=1:length(handles.clickX)
        %if (handles.clickFrame(k) == handles.curImgI) || showAll
        difFrame = handles.curImgI - handles.clickFrame(k);
        if (difFrame>=0 && difFrame<=8.66*5) || showAll
            %curSeg = handles.GTSegList(k);
            x = handles.clickX(k);
            y = handles.clickY(k);
            hold on,
            if strcmp(handles.clickType{k},'Feces')
                h=plot(x,y,'or');
                set(h,'ButtonDownFcn',{@imgClickCallback,hObject});
                h=text(x+2,y,num2str(k),'Color','Red');
                set(h,'ButtonDownFcn',{@imgClickCallback,hObject});
            elseif strcmp(handles.clickType{k},'Urine')
                h=plot(x,y,'og');
                set(h,'ButtonDownFcn',{@imgClickCallback,hObject});
                h=text(x+2,y,num2str(k),'Color','Green');
                set(h,'ButtonDownFcn',{@imgClickCallback,hObject});
            elseif strcmp(handles.clickType{k},'Shifted Feces')
                h=plot(x,y,'om');
                set(h,'ButtonDownFcn',{@imgClickCallback,hObject});
                h=text(x+2,y(1),num2str(k),'Color','Magenta');
                set(h,'ButtonDownFcn',{@imgClickCallback,hObject});
            elseif strcmp(handles.clickType{k},'Unknown')
                h=plot(x,y,'oy');
                set(h,'ButtonDownFcn',{@imgClickCallback,hObject});
                h=text(x+2,y(1),num2str(k),'Color','Yellow');
                set(h,'ButtonDownFcn',{@imgClickCallback,hObject});
            elseif strcmp(handles.clickType{k},'Auto Feces')
                h=plot(x,y,'+r');
                set(h,'ButtonDownFcn',{@imgClickCallback,hObject});
                h=text(x-2,y,num2str(k),'Color','Red','HorizontalAlignment','right');
                set(h,'ButtonDownFcn',{@imgClickCallback,hObject});
            elseif strcmp(handles.clickType{k},'Auto Urine')
                h=plot(x,y,'+g');
                set(h,'ButtonDownFcn',{@imgClickCallback,hObject});
                h=text(x-2,y,num2str(k),'Color','Green','HorizontalAlignment','right');
                set(h,'ButtonDownFcn',{@imgClickCallback,hObject});
            elseif strcmp(handles.clickType{k},'Auto Shifted Feces')
                h=plot(x,y,'+m');
                set(h,'ButtonDownFcn',{@imgClickCallback,hObject});
                h=text(x-2,y(1),num2str(k),'Color','Magenta','HorizontalAlignment','right');
                set(h,'ButtonDownFcn',{@imgClickCallback,hObject});
            elseif strcmp(handles.clickType{k},'Auto BG')
                h=plot(x,y,'+k');
                set(h,'ButtonDownFcn',{@imgClickCallback,hObject});
                h=text(x-2,y(1),num2str(k),'Color','Yellow','HorizontalAlignment','right');
                set(h,'ButtonDownFcn',{@imgClickCallback,hObject});
            end
        end
    end
end
axes(handles.axes1);
impixelinfo%celsius





set(handles.titleText,'String',['#', num2str(handles.curImgI) , ' of ' ,num2str(length(handles.imgsList)),' ',fullfile(handles.imgDir,name)]);
%title(['#', num2str(handles.curImgI) , ' ' ,name], 'Interpreter', 'none');
set(handles.framesSlider,'Value',handles.curImgI);

function imgClickCallback(objectHandle,event,hObject)
%global IrImgVec
%global imgVecAvailable

handles = guidata(hObject);
disp(['click', num2str(event.IntersectionPoint)]);

x = round(event.IntersectionPoint(1));
y = round(event.IntersectionPoint(2));
%[rows,cols,dim] = size(IrImgVec);
if event.Button==1
    %   r = 0;
    %   x = max(x,r+1);
    %    y = max(y,r+1);
    %    x = min(x,cols-r);
    %    y = min(y,rows-r);

    handles.clickX(end+1) = x;
    handles.clickY(end+1) = y;
    urineType=handles.fecesUrinationSelection.SelectedObject.String;
    handles.clickType{end+1} = urineType;
    handles.clickFrame(end+1)= handles.curImgI;

    handles = updateRoisList(handles);
    handles.needToSave = true;
    %      if imgVecAvailable
    %         vec = IrImgVec(y-r:y+r,x-r:x+r,:);
    %         handles.clickVals{length(handles.clickX)} = squeeze(mean(vec,[1,2]));
    %      end
else
    if length(handles.clickX>0)
        distX = handles.clickX - x;
        distY = handles.clickY - y;
        distSqr = distX.^2 + distY.^2;

        [vals,ind] = sort(distSqr,'ascend');
        if vals(1)< 20^2
            handles.clickX(ind(1)) = [];
            handles.clickY(ind(1)) = [];
            handles.clickType(ind(1)) = [];
            handles.clickFrame(ind(1)) = [];
        end
        handles = updateRoisList(handles);
        handles.needToSave = true;
    end
end

handles = UpdateDisplay(hObject,handles);
guidata(hObject, handles);


% --- Executes on button press in stopBn.
function stopBn_Callback(hObject, eventdata, handles)
% hObject    handle to stopBn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.stopBn,'Value',0);


% --- Executes on button press in next1Bn.
function next1Bn_Callback(hObject, eventdata, handles)
% hObject    handle to next1Bn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.curImgI = min(handles.curImgI + 1,length(handles.imgsList));
handles = UpdateDisplay(hObject,handles);
guidata(hObject,handles);


% --- Executes on button press in next10Bn.
function next10Bn_Callback(hObject, eventdata, handles)
% hObject    handle to next10Bn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
fps = handles.fps;
handles.curImgI = min(handles.curImgI + round(fps),length(handles.imgsList));
handles = UpdateDisplay(hObject,handles);
guidata(hObject,handles);


% --- Executes on button press in next100Bn.
function next100Bn_Callback(hObject, eventdata, handles)
% hObject    handle to next100Bn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
fps = handles.fps;
handles.curImgI = min(handles.curImgI + round(fps*60),length(handles.imgsList));
handles = UpdateDisplay(hObject,handles);
guidata(hObject,handles);


% --- Executes on button press in prev1Bn.
function prev1Bn_Callback(hObject, eventdata, handles)
% hObject    handle to prev1Bn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.curImgI = max(handles.curImgI - 1,1);
handles = UpdateDisplay(hObject,handles);
guidata(hObject,handles);

% --- Executes on button press in prev10Bn.
function prev10Bn_Callback(hObject, eventdata, handles)
% hObject    handle to prev10Bn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
fps = handles.fps;
handles.curImgI = max(handles.curImgI - round(fps),1);
handles = UpdateDisplay(hObject,handles);
guidata(hObject,handles);

% --- Executes on button press in prev100Bn.
function prev100Bn_Callback(hObject, eventdata, handles)
% hObject    handle to prev100Bn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
fps = handles.fps;
handles.curImgI = max(handles.curImgI - round(fps*60),1);
handles = UpdateDisplay(hObject,handles);
guidata(hObject,handles);

% --- Executes on button press in DetectBn.
function DetectBn_Callback(hObject, eventdata, handles)



function handles = markCageFloor(handles,isHab)
axes(handles.axes1)
%set(handles.imgHandle,'ButtonDownFcn',{});
[BW,xi2,yi2] = roipoly();
if isHab
    handles.habCageX = xi2;
    handles.habCageY = yi2;
    handles.habCageMask = BW;
else
    handles.trialCageX = xi2;
    handles.trialCageY = yi2;
    handles.trialCageMask = BW;
end
%set(handles.imgHandle,'ButtonDownFcn',{@imgClickCallback,hObject});


% --- Executes on button press in markHabCageBn.
function markHabCageBn_Callback(hObject, eventdata, handles)
% hObject    handle to markHabCageBn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = markCageFloor(handles,true);
handles.needToSave =true;
handles = UpdateDisplay(hObject,handles);
guidata(hObject,handles);

% --- Executes on button press in markTrialCageBn.
function markTrialCageBn_Callback(hObject, eventdata, handles)
% hObject    handle to markTrialCageBn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = markCageFloor(handles,false);
handles.needToSave =true;
handles = UpdateDisplay(hObject,handles);
guidata(hObject,handles);

% --- Executes on button press in markTrialBBBn.
function markTrialBBBn_Callback(hObject, eventdata, handles)
% hObject    handle to markTrialBBBn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
axes(handles.axes1)
[BW,xi2,yi2] = roipoly();
handles.trialBbX = xi2;
handles.trialBbY = yi2;
handles.trialBbMask = BW;
handles.needToSave =true;
handles = UpdateDisplay(hObject,handles);
%hold on,plot(xi2,yi2,'r');
%hold off
guidata(hObject,handles);

% --- Executes on button press in markHabBB.
function markHabBB_Callback(hObject, eventdata, handles)
% hObject    handle to markHabBB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
axes(handles.axes1)
[BW,xi2,yi2] = roipoly();
handles.habBbX = xi2;
handles.habBbY = yi2;
handles.habBbMask = BW;
handles.needToSave =true;
handles = UpdateDisplay(hObject,handles);
%hold on,plot(xi2,yi2,'r');
%hold off
guidata(hObject,handles);

%if ~isempty(handles.bbMask)
%    LoadVideoToMem(handles.imgDir,handles.imgList,handles.imgNUC);
%end



% --- Executes on button press in changeContrastBn.
function changeContrastBn_Callback(hObject, eventdata, handles)
% hObject    handle to changeContrastBn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.contInd =  handles.contInd+1;
if handles.contInd > size(handles.minMaxDeg,1)
    handles.contInd = 1;
end
set(handles.contrastText,'String',['C',num2str(handles.contInd)]);
handles = UpdateDisplay(hObject,handles);
guidata(hObject,handles);



function minFecesAreaEdit_Callback(hObject, eventdata, handles)
% hObject    handle to minFecesAreaEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of minFecesAreaEdit as text
%        str2double(get(hObject,'String')) returns contents of minFecesAreaEdit as a double


% --- Executes during object creation, after setting all properties.
function minFecesAreaEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to minFecesAreaEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function maxFecesAreaEdit_Callback(hObject, eventdata, handles)
% hObject    handle to maxFecesAreaEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of maxFecesAreaEdit as text
%        str2double(get(hObject,'String')) returns contents of maxFecesAreaEdit as a double


% --- Executes during object creation, after setting all properties.
function maxFecesAreaEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to maxFecesAreaEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function minUrineAreaEdit_Callback(hObject, eventdata, handles)
% hObject    handle to minUrineAreaEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of minUrineAreaEdit as text
%        str2double(get(hObject,'String')) returns contents of minUrineAreaEdit as a double


% --- Executes during object creation, after setting all properties.
function minUrineAreaEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to minUrineAreaEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function maxUrineAreaEdit_Callback(hObject, eventdata, handles)
% hObject    handle to maxUrineAreaEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of maxUrineAreaEdit as text
%        str2double(get(hObject,'String')) returns contents of maxUrineAreaEdit as a double


% --- Executes during object creation, after setting all properties.
function maxUrineAreaEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to maxUrineAreaEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function habituationFramesStart_Callback(hObject, eventdata, handles)
% hObject    handle to habituationFramesStart (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of habituationFramesStart as text
%        str2double(get(hObject,'String')) returns contents of habituationFramesStart as a double
handles.needToSave =true;
guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function habituationFramesStart_CreateFcn(hObject, eventdata, handles)
% hObject    handle to habituationFramesStart (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function habituationFramesEnd_Callback(hObject, eventdata, handles)
% hObject    handle to habituationFramesEnd (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of habituationFramesEnd as text
%        str2double(get(hObject,'String')) returns contents of habituationFramesEnd as a double
handles.needToSave =true;
guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function habituationFramesEnd_CreateFcn(hObject, eventdata, handles)
% hObject    handle to habituationFramesEnd (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function minTimeEdit_Callback(hObject, eventdata, handles)
% hObject    handle to minTimeEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of minTimeEdit as text
%        str2double(get(hObject,'String')) returns contents of minTimeEdit as a double


% --- Executes during object creation, after setting all properties.
function minTimeEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to minTimeEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function minHiddenTimeEdit_Callback(hObject, eventdata, handles)
% hObject    handle to minHiddenTimeEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of minHiddenTimeEdit as text
%        str2double(get(hObject,'String')) returns contents of minHiddenTimeEdit as a double


% --- Executes during object creation, after setting all properties.
function minHiddenTimeEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to minHiddenTimeEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end




function trialStartFrames_Callback(hObject, eventdata, handles)
% hObject    handle to trialStartFrames (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of trialStartFrames as text
%        str2double(get(hObject,'String')) returns contents of trialStartFrames as a double
handles.needToSave =true;
guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function trialStartFrames_CreateFcn(hObject, eventdata, handles)
% hObject    handle to trialStartFrames (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function trialEndFrames_Callback(hObject, eventdata, handles)
% hObject    handle to trialEndFrames (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of trialEndFrames as text
%        str2double(get(hObject,'String')) returns contents of trialEndFrames as a double
handles.needToSave =true;
guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function trialEndFrames_CreateFcn(hObject, eventdata, handles)
% hObject    handle to trialEndFrames (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function gotoEdit_Callback(hObject, eventdata, handles)
% hObject    handle to gotoEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of gotoEdit as text
%        str2double(get(hObject,'String')) returns contents of gotoEdit as a double


% --- Executes during object creation, after setting all properties.
function gotoEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to gotoEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in gotoFrameBn.
function gotoFrameBn_Callback(hObject, eventdata, handles)
% hObject    handle to gotoFrameBn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.curImgI = str2double(get(handles.gotoEdit,'String'));
handles = UpdateDisplay(hObject,handles);
guidata(hObject,handles);


function AddToLog(handles,str)

curStr = handles.logText.String;
c = newline;
if isempty(curStr)
    newStr = string(str);
else
    newStr = [curStr;string(str)];
end
handles.logText.String = newStr;

% --- Executes on button press in saveBn.
function handles = saveBn_Callback(hObject, eventdata, handles)
% hObject    handle to saveBn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.logText.String =''
AddToLog(handles,'Saving...')
params = getParams();
if 1
    [vidId,isTest,handles.vidData] = GetVidId(handles.imgDir,params.vidDir);
    if ~isempty(vidId)
        AddToLog(handles,['VidId=',num2str(vidId), ' isTestVid=',num2str(isTest)]);
    else
        AddToLog(handles,['VidId not defined']);
    end
else   
    handles.vidData=[];
end

pause(0.1);
outPath = fullfile(handles.imgDir,'GT_Detections.xlsx');
%s.Detections = handles.GTSegList;

%save just the manual labeling. the auto stays non changed:
manualType = true(1,length(handles.clickType));
for k=1:length(manualType)
    if length(strfind(lower(handles.clickType{k}),'auto'))
        manualType(k) = false;
    end
end

x = handles.clickX(manualType);
if ~isempty(x)
    y = handles.clickY(manualType);
    frameIndex = handles.clickFrame(manualType);
    type = handles.clickType(manualType);
    T =table(x,y,frameIndex,type);
    if exist(outPath,'file')%current tagging is empty, so we delete old tagging file
        delete(outPath)
    end
    writetable(T,outPath);
else
    if exist(outPath,'file')%current tagging is empty, so we delete old tagging file
        delete(outPath)
    end
    AddToLog(handles,'*No tagging of urine\feces to save*')
end

outPath = fullfile(handles.imgDir,'BBandCageContours.xml');

habStartFrame = str2num(get(handles.habituationFramesStart,'String'));
habEndFrame = str2num(get(handles.habituationFramesEnd,'String'));

trialStartFrame = str2num(get(handles.trialStartFrames,'String'));
trialEndFrame = str2num(get(handles.trialEndFrames,'String'));

s.habCage = struct('habCageX',handles.habCageX,'habCageY',handles.habCageY);
s.habBB = struct('habBbX',handles.habBbX,'habBbY',handles.habBbY);
s.trialCage = struct('trialCageX',handles.trialCageX,'trialCageY',handles.trialCageY);
s.trialBB = struct('trialBbX',handles.trialBbX,'trialBbY',handles.trialBbY);
s.trialFrames = struct('trialStartFrame',trialStartFrame,'trialEndFrame',trialEndFrame);
s.habFrames = struct('habStartFrame',habStartFrame,'habEndFrame',habEndFrame);
if ~isempty(handles.stim1Line)
    s.stim1LineX = handles.stim1Line(:,1);
    s.stim1LineY = handles.stim1Line(:,2);
end
if ~isempty( handles.stim2Line)
    s.stim2LineX = handles.stim2Line(:,1);
    s.stim2LineY = handles.stim2Line(:,2);
end

if trialStartFrame==0 || trialEndFrame==0 || habStartFrame==0||habEndFrame==0
    AddToLog(handles,'*habituation or trial frames not specified*')
end

if isempty(handles.stim1Line)
    AddToLog(handles,'*stimulus 1 line not marked')
end
if isempty(handles.stim2Line)
    AddToLog(handles,'*stimulus 2 line not marked')
end

if isempty(handles.stim2Line)
    AddToLog(handles,'*stimulus 2 line not marked')
end
if handles.tagFinished.Value==0
    AddToLog(handles,'Finished tagging this video check box is not checked')
end
s.tagFinished = handles.tagFinished.Value;

writestruct(s,outPath)
if ~isempty(handles.trialCageMask)
    imwrite(handles.trialCageMask,fullfile(handles.imgDir,'trialCageMask.bmp'));
else
    AddToLog(handles,'*No trialCageMask to save*')
end
if ~isempty(handles.trialBbMask)
    imwrite(handles.trialBbMask,fullfile(handles.imgDir,'trialBbMask.bmp'));
else
    AddToLog(handles,'*No trialBbMask to save*')
end
if ~isempty(handles.habCageMask)
    imwrite(handles.habCageMask,fullfile(handles.imgDir,'habCageMask.bmp'));
else
    AddToLog(handles,'*No habCageMask to save*')
end
if ~isempty(handles.habBbMask)
    imwrite(handles.habBbMask,fullfile(handles.imgDir,'habBbMask.bmp'));
else
    AddToLog(handles,'*No habBbMask to save*')
end

AddToLog(handles,'Saving done')
handles.needToSave =false;
guidata(hObject,handles);

% --- Executes on selection change in roisList.
function roisList_Callback(hObject, eventdata, handles)
% hObject    handle to roisList (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns roisList contents as cell array
%        contents{get(hObject,'Value')} returns selected item from roisList
if length(handles.clickX) > 0
    roisSelected = get(handles.roisList,'Value');
    handles.curImgI = handles.clickFrame(roisSelected);

    global imgVecAvailable;
    if imgVecAvailable
        global IrImgVec;

        x = handles.clickX(roisSelected);
        y = handles.clickY(roisSelected);
        frameInd = handles.clickFrame(roisSelected);
        nFrames = size(IrImgVec,3);
        framesRange = max(1,frameInd-500):min(frameInd+500,nFrames);
        graphs = squeeze(IrImgVec(y,x,framesRange));
        axes(handles.graphAxes)
        hold off, plot(framesRange,graphs)
        grid minor
    end
end

handles= UpdateDisplay(hObject,handles);
%CalcGraphsForRois(handles)

guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function roisList_CreateFcn(hObject, eventdata, handles)
% hObject    handle to roisList (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in deleteCurSeg.
function deleteCurSeg_Callback(hObject, eventdata, handles)
% hObject    handle to deleteCurSeg (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if length(handles.clickX) == 0
    set(handles.roisList,'String',{});
    return;
end
roisSelected = get(handles.roisList,'Value');
handles.clickX(roisSelected) = [];
handles.clickY(roisSelected) = [];
handles.clickFrame(roisSelected) = [];
handles.clickType(roisSelected) = [];

%handles.GTSegList(roisSelected) = [];

handles = updateRoisList(handles);
handles= UpdateDisplay(hObject,handles);
guidata(hObject,handles);

% --- Executes on button press in showAllSeg.
function showAllSeg_Callback(hObject, eventdata, handles)
% hObject    handle to showAllSeg (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of showAllSeg
handles= UpdateDisplay(hObject,handles);
guidata(hObject,handles);


% --- Executes on button press in loadVidtoMemBn.
function loadVidtoMemBn_Callback(hObject, eventdata, handles)
% hObject    handle to loadVidtoMemBn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
LoadVideoToMem(handles.imgDir,handles.imgsList,handles.imgNUC);
%if ~isempty(handles.bbMask)
%    LoadVideoToMem(handles);
%end


% --- Executes on button press in markStim1.
function markStim1_Callback(hObject, eventdata, handles)
% hObject    handle to markStim1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
h1 = drawline('SelectedColor','green');
handles.stim1Line = get(h1).Position;
delete(h1);
handles.needToSave =true;
handles= UpdateDisplay(hObject,handles);
guidata(hObject,handles);

% --- Executes on button press in markStim2.
function markStim2_Callback(hObject, eventdata, handles)
% hObject    handle to markStim2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
h2 = drawline('SelectedColor','red');
handles.stim2Line = get(h2).Position;
delete(h2);
handles.needToSave =true;
handles= UpdateDisplay(hObject,handles);
guidata(hObject,handles);


% --- Executes on button press in setHabStartBn.
function setHabStartBn_Callback(hObject, eventdata, handles)
% hObject    handle to setHabStartBn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.habituationFramesStart,'String',num2str(handles.curImgI))

% --- Executes on button press in setHabEnd.
function setHabEnd_Callback(hObject, eventdata, handles)
% hObject    handle to setHabEnd (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.habituationFramesEnd,'String',num2str(handles.curImgI))


% --- Executes on button press in setTrialStartBn.
function setTrialStartBn_Callback(hObject, eventdata, handles)
% hObject    handle to setTrialStartBn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.trialStartFrames,'String',num2str(handles.curImgI))


% --- Executes on button press in setTrialEndBn.
function setTrialEndBn_Callback(hObject, eventdata, handles)
% hObject    handle to setTrialEndBn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.trialEndFrames,'String',num2str(handles.curImgI))


% --- Executes on slider movement.
function framesSlider_Callback(hObject, eventdata, handles)
% hObject    handle to framesSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
value = get(handles.framesSlider,'Value');
handles.curImgI = round(value);
handles= UpdateDisplay(hObject,handles);
guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function framesSlider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to framesSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on button press in openDirBn.
function openDirBn_Callback(hObject, eventdata, handles)
% hObject    handle to openDirBn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
winopen(handles.imgDir);

function [baseDir,dirList,curDirInd] = GetVideoListAndCurVidIndex(imgDir)
if imgDir(end)=='\'
    imgDir = imgDir(1:end-1);
end
curImgDir = imgDir;
[baseDir,name,~] = fileparts(curImgDir);
dirList = dir(baseDir);
isDirVec = false(length(dirList),1);
for k=1:length(dirList)
    isDirVec(k)= dirList(k).isdir;
    if strcmp(dirList(k).name,'.') || strcmp(dirList(k).name,'..') || strcmp(dirList(k).name,'NUC')
        isDirVec(k) = false;
    end
end
dirList = dirList(isDirVec);

curDirInd=[];
for k=1:length(dirList)
    if strcmp(dirList(k).name,name)
        curDirInd = k;
        disp(['video # (before changing) is:',num2str(k)])
        return;
    end
end

% --- Executes on button press in nextVid.
function nextVid_Callback(hObject, eventdata, handles)
% hObject    handle to nextVid (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if handles.needToSave
    opts.Default = 'Cancel';
    opts.Interpreter = 'none';
    answer = questdlg('Save Before Continue?','Last changes were not saved',...
        'Yes','No','Cancel',opts);
    if strcmp(answer,'Cancel')
        return;
    elseif strcmp(answer,'Yes')
        handles = saveBn_Callback(hObject, eventdata, handles);
    end
    handles.needToSave =false;
end

[baseDir,dirList,k] = GetVideoListAndCurVidIndex(handles.imgDir);
if ~isempty(k) && length(dirList) > 1
    if k<length(dirList)
        nextDir = fullfile(baseDir,dirList(k+1).name);
        disp(['switching to video: ', nextDir])
        loadBn_Callback(hObject, eventdata, handles, nextDir);
    else
        disp(['This is the last video. cant switch to next video'])
    end
else
    disp(['cant find other videos'])
end


% --- Executes on button press in prevVideo.
function prevVideo_Callback(hObject, eventdata, handles)
% hObject    handle to prevVideo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if handles.needToSave
    opts.Default = 'Cancel';
    opts.Interpreter = 'none';
    answer = questdlg('Save Before Continue?','Last changes were not saved',...
        'Yes','No','Cancel',opts);
    if strcmp(answer,'Cancel')
        return;
    elseif strcmp(answer,'Yes')
        handles = saveBn_Callback(hObject, eventdata, handles);
    end
    handles.needToSave = false;
end

[baseDir,dirList,k] = GetVideoListAndCurVidIndex(handles.imgDir);


if ~isempty(k) && length(dirList) > 1
    if k>1
        prevDir = fullfile(baseDir,dirList(k-1).name);
        disp(['switching to video: ', prevDir])
        loadBn_Callback(hObject, eventdata, handles, prevDir);
    else
        disp(['This is the first video. cant switch to previous video'])
    end
else
    disp(['cant find other videos'])
end


% --- Executes on button press in UknonwnType.
function UknonwnType_Callback(hObject, eventdata, handles)
% hObject    handle to UknonwnType (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of UknonwnType


% --- Executes on button press in FecesBn.
function FecesBn_Callback(hObject, eventdata, handles)
% hObject    handle to FecesBn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of FecesBn


% --- Executes on button press in setDetectionType.
function setDetectionType_Callback(hObject, eventdata, handles)
% hObject    handle to setDetectionType (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if length(handles.clickX) == 0
    set(handles.roisList,'String',{});
    return;
end
roisSelected = get(handles.roisList,'Value');
handles.clickType{roisSelected} = handles.fecesUrinationSelection.SelectedObject.String;

%handles.GTSegList(roisSelected) = [];

handles = updateRoisList(handles);
handles.needToSave = true;
handles= UpdateDisplay(hObject,handles);
guidata(hObject,handles);


% --- Executes on button press in tagFinished.
function tagFinished_Callback(hObject, eventdata, handles)
% hObject    handle to tagFinished (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of tagFinished


% --- Executes on button press in showMaxIm.
function showMaxIm_Callback(hObject, eventdata, handles)
% hObject    handle to showMaxIm (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of showMaxIm
handles= UpdateDisplay(hObject,handles);
guidata(hObject,handles);

% --- Executes on button press in resetMaxImBn.
function resetMaxImBn_Callback(hObject, eventdata, handles)
% hObject    handle to resetMaxImBn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.maxIm(:) = 0;
handles= UpdateDisplay(hObject,handles);
guidata(hObject,handles);


% --- Executes on slider movement.
function gammaSlider_Callback(hObject, eventdata, handles)
% hObject    handle to gammaSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
handles= UpdateDisplay(hObject,handles);
guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function gammaSlider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to gammaSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on button press in openFigBn.
function openFigBn_Callback(hObject, eventdata, handles)
% hObject    handle to openFigBn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles= UpdateDisplay(hObject,handles,true);
impixelinfo
guidata(hObject,handles);


% --- Executes on button press in copyBlackBodyFromHabituationBn.
function copyBlackBodyFromHabituationBn_Callback(hObject, eventdata, handles)
% hObject    handle to copyBlackBodyFromHabituationBn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.trialBbX = handles.habBbX;
handles.trialBbY = handles.habBbY;
handles.trialBbMask = handles.habBbMask;
handles.needToSave =true;
handles = UpdateDisplay(hObject,handles);
%hold on,plot(xi2,yi2,'r');
%hold off
guidata(hObject,handles);


% --- Executes on button press in openVisVid.
function openVisVid_Callback(hObject, eventdata, handles)
% hObject    handle to openVisVid (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if ~isempty(handles.vidData)
    visVid = handles.vidData.visVid{1};
    if exist(visVid,'file') %file
        [path,name,ext] = fileparts(visVid);
        %winopen(path);
        winopen(visVid);
    elseif exist(vidVid,'dir') %folder
        winopen(visVid);
    else
        msgbox("vis vid was not found");
    end
end



% --- Executes on button press in hideTaggingCheckbox.
function hideTaggingCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to hideTaggingCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = UpdateDisplay(hObject,handles);
guidata(hObject,handles);


% --- Executes on button press in rotate180.
function rotate180_Callback(hObject, eventdata, handles)
% hObject    handle to rotate180 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of rotate180
handles = UpdateDisplay(hObject,handles);
guidata(hObject,handles);


% --- Executes on button press in pushbutton41.
function pushbutton41_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton41 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in copyCageFromTrialBn.
function copyCageFromTrialBn_Callback(hObject, eventdata, handles)
% hObject    handle to copyCageFromTrialBn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.habCageX = handles.trialCageX;
handles.habCageY = handles.trialCageY;
handles.habCageMask = handles.trialCageMask;
handles.needToSave =true;
handles = UpdateDisplay(hObject,handles);
guidata(hObject,handles);


% --- Executes on button press in copyCageFromHab.
function copyCageFromHab_Callback(hObject, eventdata, handles)
% hObject    handle to copyCageFromHab (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.trialCageX = handles.habCageX;
handles.trialCageY = handles.habCageY;
handles.trialCageMask = handles.habCageMask;
handles.needToSave =true;
handles = UpdateDisplay(hObject,handles);
guidata(hObject,handles);



function gotoVideoEdit_Callback(hObject, eventdata, handles)
% hObject    handle to gotoVideoEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of gotoVideoEdit as text
%        str2double(get(hObject,'String')) returns contents of gotoVideoEdit as a double


% --- Executes during object creation, after setting all properties.
function gotoVideoEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to gotoVideoEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in gotoVideo.
function gotoVideo_Callback(hObject, eventdata, handles)
% hObject    handle to gotoVideo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

targetVidId = str2num(handles.gotoVideoEdit.String);
params = getParams();
[dirList,vidsTable,vidType, baseDir, isMale, isWT, isSubjectStressed] = GetVidsList(params.vidDir);

if handles.needToSave
    opts.Default = 'Cancel';
    opts.Interpreter = 'none';
    answer = questdlg('Save Before Continue?','Last changes were not saved',...
        'Yes','No','Cancel',opts);
    if strcmp(answer,'Cancel')
        return;
    elseif strcmp(answer,'Yes')
        handles = saveBn_Callback(hObject, eventdata, handles);
    end
    handles.needToSave =false;
end

if targetVidId >=1 || targetVidId<=length(dirList)    
    nextDir = fullfile(params.vidDir,dirList{targetVidId});
    disp(['switching to video: ', nextDir])    
    loadBn_Callback(hObject, eventdata, handles, nextDir);    
else
    disp(['cant find this video'])
end
