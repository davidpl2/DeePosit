function [bgCordXH,bgCordYH,bgTypeH,bgFrameH] = GetBGRandCords( habCageMask, habFrames, nBGHab)

[habI,habJ] = find(habCageMask);
bgCordInd = randi(length(habI),nBGHab,1);
        
bgCordXH = habJ(bgCordInd);
bgCordYH = habI(bgCordInd);
bgTypeH = cell(nBGHab,1);
for kk = 1:nBGHab
    bgTypeH{kk} = 'BG';
end
relevantFrames = habFrames(1):habFrames(2);
bgFrameH = randi(length(relevantFrames) ,nBGHab,1);
bgFrameH = relevantFrames(bgFrameH);
bgFrameH = bgFrameH(:);
