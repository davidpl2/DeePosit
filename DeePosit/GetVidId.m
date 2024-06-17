function [vidId, isTest, vidData] = GetVidId(srcDir,baseDir)

[dirList,vidsTable,vidType, ~] = GetVidsList(baseDir);

ind = strfind(srcDir,'IR_Raw_Data');
if ~isempty(ind)    
    srcDir = srcDir(ind(1):end);
end
if srcDir(end)=='\' || srcDir(end)=='/'
    srcDir = srcDir(1:end-1);
end
vidDir = vidsTable.vidDir;

vidId = find(strcmp(vidsTable.vidDir,srcDir));
if length(vidId)>1
    error('two videos have the same id')
end
isTest = [];
vidData = [];
if ~isempty(vidId)
    isTest = ~vidsTable.isTrain(vidId);
    vidData = vidsTable(vidId,:);
end