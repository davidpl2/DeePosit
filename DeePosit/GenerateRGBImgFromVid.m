function rgbIm = GenerateRGBImgFromVid(patchMat,flip,rot)

[rows,cols,nImgs] = size(patchMat);

rgbIm = zeros(rows,cols*nImgs/3,3,'uint16');
curChannel = 1;
curColumn = 1;
for k=1:nImgs
    curIm = patchMat(:,:,k);
    if flip
        curIm = curIm(:,end:-1:1);
    end
    if rot
        curIm = imrotate(curIm,rot);
    end
    rgbIm(:,curColumn:curColumn+cols-1,curChannel) = curIm;
    curChannel = curChannel+1;
    if curChannel==4
        curChannel = 1;
        curColumn = curColumn+cols;
    end
end
    
    