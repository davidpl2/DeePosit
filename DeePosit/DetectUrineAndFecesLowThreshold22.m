function outPath = DetectUrineAndFecesLowThreshold22(startI,endI,outsideMask,imgsList,imgDir,outDirPostfix,habFrames,trialFrames,vidOutputDir)

global IrImgVec
%global imgVecAvailable
fps = 8.663;

%minTemp = 27;
%maxTemp = 38;
%minSizeFeces = 5;
%maxSizeFeces = 25;
%minSizeUrine = 25;
%maxSizeUrine = 400;%30*30 pixels
%minTime = 5; %urine\feces should be visible at least this time
%verStr = '1.13LowThres';
verStr = '1.22LowThres';%1.19 and 1.20 is the same alg.
%LOG:
% ver 1.1: substract oldImNoMouse instead of bgImage
% ver 1.2: allow detections that touches the mouse or the cage borders
% ver 1.3: prevImC is initialized with bgImage
% ver 1.4: a. threshold changed, b.overlap with cage border and mice c. detection in atleast 2 frames
% ver 1.5: dilation of mouse mask reduced from strel(disk,4) to
% strel(disk,2) and cooldown is compared to detection instead of baseline
% value
% ver 1.6: separate theshold for cooldown in compare to base (because of
% too much detections)
% ver 1.7: cancel theshold for cooldown in compare to base and but at-least
% 0.5 of the rise should be cooled-down and atleast 0.5deg
% cooldown(compared to peak temprature).
% ver 1.8: same threshold for mouse detection and rise detection. larger
% maximal size for detection (900), minDeltaMouseMask = 1; instead of 1.5
% and minDeltaTUrine\Feces = 1 instead of 0.5, minCooldown=1 instead of 0.5
% ver 1.9 - the bg image should be dilated to remove dark spots, otherwise
% occlusion of the dark spots by the undetected tail part causes
% detections. the mouse segment should be simply the largest segment
% because sometimes the mouse is not fully visible (behind the wall)
% ver 1.10 - mouse mask must be inside the cage (ignore the mask of the
% reflection
% ver 1.11 - floor temp is the median of the oldImNoMouse inside the cage
% mask and in pixels outside the maskMouse and prevMouseMask. The diffImg is computed
% as the dif between imC and max(floorTemp,oldImNoMouse) instead of dilate(oldImNoMouse).
% This is done to cope with black spots, mostly in the SNP sessions.
% additionaly, a vector for mouse position is recorded. also,
% minHiddenTime=30 instead of 40 and minDeltaTUrine,minDeltaTFeces and
% minCooldown are 1.5 instead of 1. recording also mouse mean and median temprature
% ver 1.12 - record the mouse mean,median,max temprature
% ver 1.13 - reducd threshold: minDeltaTUrine = 1.1,minDeltaTFeces =
% 1.1,minCooldown = 1.1; instead of 1.5
% ver 1.14, save the mask of the mouse for each as a sparse matrix, limit
% the temprature measurment to the region of the mouse inside the cage
% floor. if the mouse stands then part of it might be outside the mask used
% for temprature.
% ver 1.15 - equal to 1.14, changed to track a new run.
% ver 1.16 - equal to 1.14 and 1.15, changed to track a new run.
% ver 1.17 - masks for computing temperature were chagned but also
% maskMouse needs to be higher than 28Deg.
%ver 1.18 separate mouse mask for urine\feces and mouse mask for
%temperature tracking. using different thresholds and no dilate for mouse
%mask for temperature tracking.
%ver 1.19: saving the mask for each detection
%ver 1.20: same as ver 1.19
%ver 1.21: mask for temperature threshold is same as regualr mask to avoid
%nans
%ver 1.22: unify pixel list to better cope with smearing of urine\small
%shifts.

minTemp = 10;
maxTemp = 39;

%minDt should be higher then the maskMouse threshold so if a mouse's tail pixel was not detected as part of the mouse mask, it will also not be detected as urine\feces
minDeltaTUrine = 1.1;
minDeltaTFeces = 1.1;
minCooldown = 1.1;
%minCooldownFromBase = 0.5;
minTempOfMouse = 28;

minSizeFeces = 2;
maxSizeFeces = 900; %check maybe larger value
minSizeUrine = 2;
maxSizeUrine = 900; %check maybe larger value

minTime = 2; % detection should found in atelast 2 frames.
minHiddenTime = round(fps*30);%new detections in the same place should be atleast 30 sec frames apart

minDeltaMouseMask = 1;
%minDeltaMouseMaskForTemp = 2;
%mouseSegmentMinSize = 600;

min_intersect = 0.01; %min overlap (intersection over union) to connect regions across frames

minSize = min(minSizeFeces,minSizeUrine);
maxSize = max(maxSizeFeces,maxSizeUrine);


rows = 288;
cols = 384;
dtype = 'uint16';
oldRegionsVec = {};
%maskBorder = handles.cageMask & ~imerode(handles.cageMask,ones(3));
%maskBorderPix = find(maskBorder);
outsideMaskPix = find(outsideMask);

cageMask = ~outsideMask;

%bgImage = GenerateBGImage(handles);
bgImageFrameRange = startI:startI+round(fps*20);
bgImage  = min(IrImgVec(:,:,bgImageFrameRange  ),[] ,3);%min of first 20 seconds

imgHistLen = round(fps)*5;%5 sec
lastFrames = zeros(rows,cols,imgHistLen);
lastFramesInd = 1;
lastFramesFull = false;
oldFramesForBg = 9;
maskMouse = true(rows,cols); %might include reflections if the mouse label is connected to the reflections label, but since this masks used to prevent urine\feces false alarams it is ok (we dont want to detect urine\feces on the refelctions).
[X,Y] = meshgrid(1:cols,1:rows);
mousePosXYFrame = zeros(endI-startI+1,3);
mouseMeanTemp = nan(endI-startI+1,12);
mouseMedTemp = nan(endI-startI+1,12);
mouseMaxTemp = nan(endI-startI+1,8);

maskMouseForTempVec = cell(endI-startI+1,1);
maskMouseCloseVec = cell(endI-startI+1,1);
masksAll = cell(endI-startI+1,6);
erodedOutsideMask = imerode(outsideMask,strel('disk',10));
for k=startI:endI
    mousePosXYFrame(k-startI+1,3) = k;

    %disp(k)
    if mod(k,500)==0
        disp([num2str(k) ,' out of ', num2str(endI)]);
    end
    imC = IrImgVec(:,:,k);

    prevMouseMask = maskMouse;
    % calc mouse mask (for preventing false alarms and computing bg image):
    if k<=bgImageFrameRange(end)
        maskMouse = (imC-bgImage) > minDeltaMouseMask;
    else
        maskMouse = (imC-oldImNoMouse) > minDeltaMouseMask;
    end

    if sum(maskMouse(:))>0
        labelMouse = bwlabel(imdilate(maskMouse,strel('disk',2)));
        stats = regionprops(labelMouse.*(~erodedOutsideMask),'Area'); %eroded added in ver 1.21 to cope with mouse climbing on net.
        sizeVec = zeros(1,length(stats));
        for r=1:length(stats)
            sizeVec(r) = stats(r).Area;
        end
        %maskMouse = (labelMouse==maxInd);
        [~,largestSegmentInd] = max(sizeVec);
        %largeSegments = find(sizeVec> mouseSegmentMinSize);
        maskMouse = ismember(labelMouse,largestSegmentInd);
        maskMouseInCage = maskMouse & (~erodedOutsideMask);   %eroded added in ver 1.21 to cope with mouse climbing on net.
        if isempty(maskMouseInCage)
            maskMouseInCage = maskMouse;
        end
    else
        maskMouseInCage=maskMouse;
    end

    masksAll(k-startI+1,:) = {[], [], [], [],sparse(maskMouse),sparse(maskMouseInCage)};
    mouseMeanTemp(k-startI+1,1) = k;
    mouseMedTemp(k-startI+1,1) = k;
    mouseMaxTemp(k-startI+1,1) = k;

    if lastFramesInd==1
        if ~lastFramesFull
            prevImC = bgImage;%ones(rows,cols)*100;
        else
            prevImC = lastFrames(:,:,end);
        end
    else
        prevImC = lastFrames(:,:,lastFramesInd-1);
    end

    imNoMouse = imC;
    imNoMouse(maskMouse) = prevImC(maskMouse);
    lastFrames(:,:,lastFramesInd) = imNoMouse;
    lastFramesInd = lastFramesInd+1;
    if lastFramesInd>imgHistLen
        lastFramesInd = 1;
        lastFramesFull =true;
    end
    if lastFramesFull
        oldestInd = lastFramesInd+[0:oldFramesForBg-1];
        oldestInd(oldestInd > imgHistLen) = oldestInd(oldestInd > imgHistLen) - imgHistLen;
    else
        oldestInd = 1:min(lastFramesInd-1,oldFramesForBg);
    end
    oldImNoMouse = min(lastFrames(:,:,oldestInd),[],3);
    mousePosXYFrame(k-startI+1,:) = [mean(X(maskMouseInCage)), mean(Y(maskMouseInCage)), k];
    floorTemp = median(oldImNoMouse(cageMask & (~maskMouse) & (~prevMouseMask)));
    difImg = imC-max(floorTemp,oldImNoMouse);
    mask0 = (imC > minTemp) & (imC < maxTemp) ...
        & (~maskMouse) & (~prevMouseMask) ...
        & (difImg > min(minDeltaTUrine,minDeltaTFeces));

    if sum(mask0(:)) == 0
        continue;
    end

    minOfFuture = min(IrImgVec(:,:,k:min(endI,k+round(fps*40))),[], 3);
    %the cooldown should be closer in time to the heat time

    %darker then the base level (before the urination)
    curCoolDown = (imC-minOfFuture);%ver 1.5
    mask0 = mask0.*(curCoolDown>minCooldown).*(curCoolDown>=0.5*difImg);%.*(coolDownFromBase > minCooldownFromBase);


    if sum(mask0(:)) == 0
        continue;
    end

    %mask0 = imclose(mask0,strel('disk',11)); %maybe reduce the radius
    mask0 = imclose(mask0,strel('disk',4));

    if sum(mask0(:)) > minSize
        labelIm = bwlabel(mask0);
        stats = regionprops(labelIm,'Area','BoundingBox','PixelIdxList','Centroid');
        for r = 1:length(stats)
            curRegion = stats(r);
            %relevant size?
            if (curRegion.Area < minSize) || (curRegion.Area > maxSize)
                continue;
            end


            %region touches mask borders
            if length(intersect(outsideMaskPix,curRegion.PixelIdxList))>0
                continue;
            end

            if sum(maskMouse(imdilate(labelIm==r,ones(3))))>0
                %overlap with mouse mask
                continue;
            end



            % check correlations:
            [maxPixel,maxPixelInd] = max(imC(curRegion.PixelIdxList));
            [cordI,cordJ] = ind2sub([rows,cols],curRegion.PixelIdxList(maxPixelInd));


            %minOfFuturePatch = minOfFuture(cordI-r:cordI+r,cordJ-r:cordJ+r); % future
            %smooth correlation

            isUrine = false;
            if (curRegion.Area> maxSizeFeces)
                isUrine = true;
            end

            %overlaps old regions?
            gotIntersection = false;
            for oldI = 1:length(oldRegionsVec)
                %we dont return to very old regions. only to active one:
                oldRegion = oldRegionsVec{oldI};
                if oldRegion.lastFrameInd <k-minHiddenTime
                    continue;
                end

                overlap = intersect(oldRegion.unifiedPixelIdxList, curRegion.PixelIdxList);

                %if length(overlap)/length(unionPix) > min_IoU
                if length(overlap)/length(curRegion.PixelIdxList) > min_intersect
                    oldRegionsVec{oldI}.unifiedPixelIdxList = union(oldRegionsVec{oldI}.unifiedPixelIdxList, curRegion.PixelIdxList);
                    [maxPixel,maxPixelInd] = max(imC(curRegion.PixelIdxList));
                    if maxPixel > oldRegionsVec{oldI}.maxPixelVal
                        [cordI,cordJ] = ind2sub([rows,cols],curRegion.PixelIdxList(maxPixelInd));
                        oldRegionsVec{oldI}.hotFrame = k;
                        oldRegionsVec{oldI}.maxCordI = cordI;
                        oldRegionsVec{oldI}.maxCordJ = cordJ;
                        oldRegionsVec{oldI}.maxPixelVal = maxPixel;
                        oldRegionsVec{oldI}.graphMaxVal = squeeze(IrImgVec(cordI,cordJ,:));
                        oldRegionsVec{oldI}.raiseVal = difImg(cordI,cordJ);
                        oldRegionsVec{oldI}.maxPixelIdxList = curRegion.PixelIdxList;
                    end

                    [maxCooldownVal,maxCooldownInd] = max(curCoolDown(curRegion.PixelIdxList));
                    if maxCooldownVal > oldRegionsVec{oldI}.maxCooldownVal
                        [cordI,cordJ] = ind2sub([rows,cols],curRegion.PixelIdxList(maxCooldownInd));
                        oldRegionsVec{oldI}.maxCooldownFrame = k;
                        oldRegionsVec{oldI}.maxCooldownI = cordI;
                        oldRegionsVec{oldI}.maxCooldownJ = cordJ;
                        oldRegionsVec{oldI}.maxCooldownVal = maxCooldownVal;
                        oldRegionsVec{oldI}.graphMaxCD = squeeze(IrImgVec(cordI,cordJ,:));
                    end

                    oldRegionsVec{oldI}.detectionCnt = oldRegionsVec{oldI}.detectionCnt + 1;
                    oldRegionsVec{oldI}.lastFrameInd = k;
                    %oldRegionsVec{oldI}.PixelIdxList = overlap;
                    gotIntersection = true;
                    break;
                end
            end
            if ~gotIntersection
                %new region but only if dt is large enough

                oldRegionsVec{end+1} = curRegion; % curRegion.PixelIdxList is blob of the detection in the first frame.
                oldRegionsVec{end}.lastFrameInd = k;
                oldRegionsVec{end}.firstFrameInd = k;
                oldRegionsVec{end}.hotFrame = k;
                oldRegionsVec{end}.maxCooldownFrame = k;
                oldRegionsVec{end}.detectionCnt = 1;
                oldRegionsVec{end}.isUrine = isUrine;
                oldRegionsVec{end}.meanTemp = mean(imC(curRegion.PixelIdxList));
                oldRegionsVec{end}.PixelIdxList = curRegion.PixelIdxList;
                oldRegionsVec{end}.maxPixelIdxList = curRegion.PixelIdxList;
                oldRegionsVec{end}.unifiedPixelIdxList = curRegion.PixelIdxList;

                [maxPixel,maxPixelInd] = max(imC(curRegion.PixelIdxList));
                [cordI,cordJ] = ind2sub([rows,cols],curRegion.PixelIdxList(maxPixelInd));
                oldRegionsVec{end}.maxCordI = cordI;
                oldRegionsVec{end}.maxCordJ = cordJ;
                oldRegionsVec{end}.maxPixelVal = maxPixel;
                oldRegionsVec{end}.graphMaxVal = squeeze(IrImgVec(cordI,cordJ,:));
                oldRegionsVec{end}.raiseVal = difImg(cordI,cordJ);

                [maxCooldownVal,maxCooldownInd] = max(curCoolDown(curRegion.PixelIdxList));
                [cordI,cordJ] = ind2sub([rows,cols],curRegion.PixelIdxList(maxCooldownInd));
                oldRegionsVec{end}.maxCooldownI = cordI;
                oldRegionsVec{end}.maxCooldownJ = cordJ;
                oldRegionsVec{end}.maxCooldownVal = maxCooldownVal;
                oldRegionsVec{end}.graphMaxCD = squeeze(IrImgVec(cordI,cordJ,:));
                disp('New Region')
            end
        end
    end
end
%save
curDateStr = datestr(now,'yyyy-mm-dd_HH-MM-SS');
outPath = fullfile(vidOutputDir,['analyzeDir_',curDateStr,outDirPostfix,verStr]);
mkdir(outPath);
disp(['saving results to: ',outPath]);

scriptPath = mfilename('fullpath');
[FILEPATH,NAME,EXT]= fileparts(scriptPath);
copyfile(fullfile(FILEPATH,'*.m'),outPath);


saveRegionVec = false(1,length(oldRegionsVec));
for oldI=1:length(oldRegionsVec)
    curRegion = oldRegionsVec{oldI};
    if (curRegion.lastFrameInd - curRegion.firstFrameInd+1) > minTime
        oldRegionsVec{oldI}.regionSaved = true;
        saveRegionVec(oldI)=true;
    end
end
oldRegionsVec = oldRegionsVec(saveRegionVec);

outFname = fullfile(outPath,'hotBlobsDetection.csv');

%oldRegionsVec{end}.maxCordI
%oldRegionsVec{end}.maxCordJ

fd = fopen(outFname,'wt');
fprintf(fd,'ID, Start Frame index, End Frame index, maxTempFrame, maxTempX, maxTempY, maxBrightness, Left, Top, Width, Height, Area at max temp frame (pixels), Start Frame Name\n');
cnt = 1;
for oldI=1:length(oldRegionsVec)
    curRegion = oldRegionsVec{oldI};
    bbox = curRegion.BoundingBox;

    oldRegionsVec{oldI}.regionSaved = true;
    fprintf(fd,[num2str(cnt) ',' num2str(curRegion.firstFrameInd) ',' num2str(curRegion.lastFrameInd) ',' num2str(curRegion.hotFrame), ',' ,num2str(curRegion.maxCordJ),',', num2str(curRegion.maxCordI), ',', num2str(curRegion.maxPixelVal) ,',' , num2str(bbox(1)) ',' num2str(bbox(2)) ',' num2str(bbox(3)) ',' num2str(bbox(4)) ',' num2str(length(curRegion.maxPixelIdxList)) ',' , imgsList(curRegion.firstFrameInd).name ' \n']);

    if 0
        imC = IrImgVec(:,:,curRegion.firstFrameInd-5);
        im4WritePrev5 = uint8((imC-15)*10);

        imC = IrImgVec(:,:,curRegion.firstFrameInd);
        im4Write = uint8((imC-15)*10);
        if curRegion.isUrine
            color = [0,255,0];
        else
            color = [255,0,0];
        end
        im4WriteP = paintBbox(im4Write, bbox, color);
        outFname = fullfile(outPath,[num2str(cnt,'%.5d'),'_',imgsList(curRegion.firstFrameInd).name]);
        imwrite(im4WritePrev5,[outFname,'_0.png']);
        imwrite(im4Write,[outFname,'_1.png']);
        imwrite(im4WriteP,[outFname,'_2.png']);
    end
    oldRegionsVec{oldI}.ID = cnt;
    cnt = cnt+1;


end
fclose(fd);
save(fullfile(outPath,'Detections.mat'),'oldRegionsVec','mousePosXYFrame','mouseMeanTemp','mouseMedTemp','mouseMaxTemp','maskMouseCloseVec','maskMouseForTempVec','masksAll')

%Save param file:
paramsFname = fullfile(outPath,'params.csv');
fd = fopen(paramsFname,'wt');
fprintf(fd,['minUrineAndFecesTemprature(C),' num2str(minTemp) '\n']);
fprintf(fd,['maxUrineAndFecesTemprature(C),' num2str(maxTemp) '\n']);
fprintf(fd,['UrineMinDeltaT(C),' num2str(minDeltaTUrine) '\n']);
fprintf(fd,['FecesMinDeltaT(C),' num2str(minDeltaTFeces) '\n']);
fprintf(fd,['minFecesArea(pixels),' num2str(minSizeFeces) '\n']);
fprintf(fd,['maxFecesArea(pixels),' num2str(maxSizeFeces) '\n']);
fprintf(fd,['minUrineArea(pixels),' num2str(minSizeUrine) '\n']);
fprintf(fd,['maxUrineArea(pixels),' num2str(maxSizeUrine) '\n']);
fprintf(fd,['ExistDuringAtleastXFrames,' num2str(minTime) '\n']);
fprintf(fd,['MayBeHiddenDuringXFrames,' num2str(minHiddenTime) '\n']);
fclose(fd);
if 0
    bgImageu8 = uint8((bgImage-15)*10);
    detectionImage = bgImage;
    detectionImageRGB = uint8((cat(3,bgImage,bgImage,bgImage)-15)*10);
    f=figure,
    subplot(1,2,1);
    imshow(bgImage,[15,30]),hold on,title('Background image + detections')
    urineMaskPerMin = cat(3,bgImage,bgImage,bgImage);
    fecesMaskPerMin = cat(3,bgImage,bgImage,bgImage);
    maskMin = 0;
    for oldI=1:length(oldRegionsVec)
        if oldRegionsVec{oldI}.regionSaved
            cord = oldRegionsVec{oldI}.Centroid;
            imC = IrImgVec(:,:,oldRegionsVec{oldI}.firstFrameInd);
            %GetImage(handles.imgDir, handles.imgsList, oldRegionsVec{oldI}.firstFrameInd, handles.imgNUC , handles.bbMask);
            pixInd = oldRegionsVec{oldI}.PixelIdxList;
            detectionImage(pixInd) = max(detectionImage(pixInd),imC(pixInd));
            temp = detectionImageRGB(:,:,2);
            temp(pixInd) = 255;
            detectionImageRGB(:,:,2) = temp;

            curMinute = 1+floor((oldRegionsVec{oldI}.firstFrameInd-startI)/(60*fps));
            if curMinute > maskMin
                if maskMin > 0
                    urineimg = cat(3,bgImageu8,bgImageu8,bgImageu8);
                    urineMaskPerMin = single(urineMaskPerMin);
                    fecesMaskPerMin = single(fecesMaskPerMin);
                    urineimg(:,:,2) = uint8(single(bgImageu8).*(1-urineMaskPerMin) + 255.*urineMaskPerMin);
                    urineimg(:,:,1) = uint8(single(bgImageu8).*(1-fecesMaskPerMin) + 255.*fecesMaskPerMin);
                    imwrite(urineimg,fullfile(outPath,['Min',num2str(int32(maskMin),'%.2d'),'_UrineAndFecesMask.png']));
                end
                urineMaskPerMin = false(rows,cols);
                fecesMaskPerMin = false(rows,cols);
                maskMin = curMinute;
            end

            str = [num2str(oldRegionsVec{oldI}.ID) ',', num2str(oldRegionsVec{oldI}.firstFrameInd/(60*fps),'%.1f')];
            if oldRegionsVec{oldI}.isUrine
                color = [0,1,0];
                urineMaskPerMin(pixInd) = true;
            else
                color = [1,0,0];
                fecesMaskPerMin(pixInd) = true;
            end
            figure(f)
            subplot(1,2,1);
            hold on,
            plot(cord(1),cord(2),'.','Color',color)
            text(cord(1),cord(2),str,'Color',color);
            subplot(1,2,2),hold off, imshow(detectionImage,[15,45]);


            %generate a plot
            cordI = oldRegionsVec{oldI}.maxCordI;
            cordJ = oldRegionsVec{oldI}.maxCordJ;
            graph = squeeze(IrImgVec(cordI,cordJ,:));
            f2 = figure,
            subplot(2,1,1)
            title(['Frame ', num2str(oldRegionsVec{oldI}.firstFrameInd)]);
            imshow(imC,[20,35]),hold on,plot(cordJ,cordI,'og');
            subplot(2,1,2)
            timeVecSec = (0:length(graph)-1)./fps;
            plot(timeVecSec,graph)
            hold on,
            detTime = timeVecSec(oldRegionsVec{oldI}.firstFrameInd);
            plot([detTime,detTime],[min(graph(:)),max(graph(:))],'g')
            plot([timeVecSec(habFrames(1)),timeVecSec(habFrames(1))],[min(graph(:)),max(graph(:))],'k')
            plot([timeVecSec(habFrames(2)),timeVecSec(habFrames(2))],[min(graph(:)),max(graph(:))],'k')
            plot([timeVecSec(habFrames(1)),timeVecSec(habFrames(2))],[max(graph(:)),max(graph(:))],'k')
            text(mean([timeVecSec(habFrames(1)),timeVecSec(habFrames(2))]),double(max(graph(:))*0.9),'Habituation','HorizontalAlignment','center');

            plot([timeVecSec(trialFrames(1)),timeVecSec(trialFrames(1))],[min(graph(:)),max(graph(:))],'k')
            plot([timeVecSec(trialFrames(2)),timeVecSec(trialFrames(2))],[min(graph(:)),max(graph(:))],'k')
            plot([timeVecSec(trialFrames(1)),timeVecSec(trialFrames(2))],[max(graph(:)),max(graph(:))],'k')
            text(mean([timeVecSec(trialFrames(1)),timeVecSec(trialFrames(2))]),double(max(graph(:))*0.9),'SP','HorizontalAlignment','center');

            xlabel('time (sec)');
            ylabel('temprature (C)');
            title(['Frame ', num2str(oldRegionsVec{oldI}.firstFrameInd)]);
            saveas(f2,fullfile(outPath,['Detection_',num2str(oldI),'_',num2str(oldRegionsVec{oldI}.firstFrameInd,'%.3d'),'.png']));
            close(f2);


        end
    end
    imwrite(uint8((detectionImage-15)*10),fullfile(outPath,'DetectionsImage.png'));
    imwrite(uint8((bgImage-15)*10),fullfile(outPath,'bgImage.png'));
    %imwrite(uint8((coolDown-15)*10),fullfile(outPath,'coolDown.png'));
    imwrite(detectionImageRGB,fullfile(outPath,'DetectionsImageGreen.png'));
    saveas(f,fullfile(outPath,'DetectionsMap.png'));


    if maskMin > 0
        urineimg = cat(3,bgImageu8,bgImageu8,bgImageu8);
        urineMaskPerMin = single(urineMaskPerMin);
        fecesMaskPerMin = single(fecesMaskPerMin);
        urineimg(:,:,2) = uint8(single(bgImageu8).*(1-urineMaskPerMin) + 255.*urineMaskPerMin);
        urineimg(:,:,1) = uint8(single(bgImageu8).*(1-fecesMaskPerMin) + 255.*fecesMaskPerMin);
        imwrite(urineimg,fullfile(outPath,['Min',num2str(maskMin,'%.2d'),'_UrineAndFecesMask.png']));
    end

    GenerateDetectionsVid(outPath);
end