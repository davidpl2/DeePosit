%compare a signle detection vs a list of gt
function isFalse = isFalseDetection(detX,detY,detFrame,detPixels, gtCordX,gtCordY,gtFrame)
%detX an detY are coordinates of a single detection 
%gtCordX and gtCordY are vectors of all gt feces\urine

fps = 8.663;

params = getParams();
[detYlist,detXlist] = ind2sub([params.imRows,params.imCols],detPixels);
distSqr = zeros(length(gtCordX),1);
for k=1:length(gtCordX)
    distSqr(k) = min ( (detXlist - gtCordX(k)).^2 + (detYlist-gtCordY(k)).^2 );
end
%distSqr = (detX - gtCordX).^2 + (detY-gtCordY).^2;
distSec = (detFrame - gtFrame)/fps;

%found = sum( (distSec<4).* (distSqr<15^2) ) >0;
%making sure that this is a false alarm
found = sum( (distSec>=-10 & distSec<=30).* (distSqr<25^2) ) >0;
isFalse = ~found;
    