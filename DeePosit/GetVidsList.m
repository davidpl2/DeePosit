%baseDir is the directory in which vidsID.csv exist
function [dirList,vidsTable,vidType, baseDir, isMale, isWT, isSubjectStressed] = GetVidsList(baseDir)

vidsTable = readtable(fullfile(baseDir,'vidsID.csv'),'delimiter',',');
disp(['using vids table: ',fullfile(baseDir,'vidsID.csv')])
dirList = vidsTable.vidDir;
vidType = vidsTable.vidType;

isMale = vidsTable.isMale;
isWT = vidsTable.isWT;
if isfield(vidsTable,'isSubjectStressed')
    isSubjectStressed = vidsTable.isSubjectStressed;
else
    isSubjectStressed = false(length(isWT),1);
end


params = getParams();

