function [imC,meanBB] = GetImage(imgDir, imgsList, imgIndex, imgNUC , bbMask, refMeanBB)
curFname = fullfile(imgDir,imgsList(imgIndex).name);
[p,name,ext] = fileparts(curFname);
if isequal(ext,'.bin')
    rows = 288;
    cols = 384;
    dtype = 'uint16';
    curIm = bImread(curFname,rows,cols,dtype,0);
else
    curIm = imread(curFname);
end
curIm = single(curIm) - imgNUC;
imC = (curIm - 27315.0)/100.0;%celsius
meanBB = [];
if ~isempty(bbMask)
    meanBB = mean(imC(bbMask));
    imC = imC-meanBB + 37;
elseif exist('refMeanBB','var')
    imC = imC-refMeanBB + 37;    
end