function absDir = makeAbsPath(relDir)
curDir = pwd;
cd(relDir)
absDir = pwd;
cd(curDir);
