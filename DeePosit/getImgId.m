function imgID = getImgId(imgList)
imgID = zeros(length(imgList),1);
for k=1:length(imgList)
    curName = imgList(k).name;
    indStart = strfind(curName,'frame_') + length('frame_');
    indEnd = strfind(curName(indStart:end),'_') + indStart-2;
    imgID(k) = str2num(curName(indStart:indEnd(1)));
end