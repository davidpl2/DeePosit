function LoadVideoToMem2(imgDir,imgsList,imgNUC,handles)
global IrImgVec
global imgVecAvailable
global oneSecDifAvailable

localPath = strrep(imgDir,'S:\','D:\');
if exist(localPath,'dir')
    imgDir = localPath;
end

rows = 288;
cols = 384;
nImages = length(imgsList);
IrImgVec = zeros(rows,cols,nImages,'single');
imgVecAvailable = false;
oneSecDifAvailable = false;

[~ ,firstHab_meanBB  ] = GetImage(imgDir, imgsList, handles.habFrames(1)  , imgNUC , handles.habBbMask);
[~ ,lastHab_meanBB   ] = GetImage(imgDir, imgsList, handles.habFrames(2)  , imgNUC , handles.habBbMask);
[~ ,firstTrial_meanBB] = GetImage(imgDir, imgsList, handles.trialFrames(1), imgNUC , handles.trialBbMask);
[~ ,lastTrial_meanBB ] = GetImage(imgDir, imgsList, handles.trialFrames(2), imgNUC , handles.trialBbMask);

for k=1:length(imgsList)
    
    if k<handles.habFrames(1)
        IrImgVec(:,:,k) = GetImage(imgDir, imgsList, k, imgNUC , [] , firstHab_meanBB);
    elseif k<=handles.habFrames(2) %during hab
        IrImgVec(:,:,k) = GetImage(imgDir, imgsList, k, imgNUC , handles.habBbMask);
    elseif k<handles.trialFrames(1) %between hab and trial
        IrImgVec(:,:,k) = GetImage(imgDir, imgsList, k, imgNUC , [], (lastHab_meanBB+firstTrial_meanBB)/2 );
    elseif k<=handles.trialFrames(2) % during trial
        IrImgVec(:,:,k) = GetImage(imgDir, imgsList, k, imgNUC , handles.trialBbMask);
    else
        IrImgVec(:,:,k) = GetImage(imgDir, imgsList, k, imgNUC , [] , lastTrial_meanBB);
    end

    if mod(k,500)==0
        disp([num2str(k),' out of ', num2str(nImages)]);
        %set(handles.loadStTxt,'String',['Loading: ',num2str(k),' out of ', num2str(nImages)]);
        %drawnow        
    end
end
disp([num2str(k),' out of ', num2str(nImages)]);
imgVecAvailable = true;
disp('Finished Loading Video');
