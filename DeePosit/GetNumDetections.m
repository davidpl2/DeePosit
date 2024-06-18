function nDetections = GetNumDetections(detectionsMatFname)

det = load(detectionsMatFname); 
nDetections = 0;
for k=1:length(det.oldRegionsVec)
    if det.oldRegionsVec{k}.regionSaved
        nDetections = nDetections+1;
    end
end