function [imgsList,imgNUC] = GetImageListAndNucIm(imgDir)

imgsList= dir(fullfile(imgDir,'*.bin'));

isNucIm = false(length(imgsList),1);
for k=1:length(imgsList)
    isNucIm(k) = isequal(imgsList(k).name(1:3),'NUC');
end
imgsList = imgsList(~isNucIm);

imgId = getImgId(imgsList);
[~,ind] = sort(imgId,'ascend');
imgsList = imgsList(ind);


fnames = dir(fullfile(imgDir,'NUC*.bin'));
if length(fnames)>1
    fnames = fnames(end);
end
if length(fnames)==1
    nucFname = fullfile(imgDir,fnames(1).name);
    disp(['using Nuc file: ',nucFname])
else
    [nucFile,pathNuc] = uigetfile(fullfile(imgDir,'NUC*.bin'),'Select a NUC File');
    nucFname = fullfile(pathNuc,nucFile);
end
rows = 288;
cols = 384;
imgNUC = bImread(nucFname,rows,cols,'float32');
imgNUC = imgNUC-mean(imgNUC(:));
