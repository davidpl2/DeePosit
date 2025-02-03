function evalOutFilePostfix = RunDeePositClassifier(inputDir,outDir)

params = getParams();

curDir = pwd;
pythonExe = params.pythonExe;
mainScript = params.mainScript;
weightFile = params.weightFile;
evalOutFilePostfix = params.evalOutFilePostfix;

if ~isequal(evalOutFilePostfix, params.classifierVer)
    error('classifier version does not match params file');
end

%change relative out path to absolute path
outDir = makeAbsPath(outDir);
[filepath,name,ext] = fileparts(weightFile);
weightFile = fullfile(makeAbsPath(filepath),[name,ext]);
inputDir = makeAbsPath(inputDir);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~isempty(inputDir)   
    cd(params.classifierWorkingDir)
    %inputDir = strrep(['"',inputDir,'"'],'\','\\');
    %outDir = strrep(['"',outDir,'"'],'\','\\');
    inputDir = ['"',inputDir,'"'];
    outDir = ['"',outDir,'"'];    
    weightFile = ['"',weightFile,'"'];
    system([pythonExe,' ',mainScript,' --output_dir ',outDir,' --enc_layers 6 --dec_layers 6 --num_queries 1 --resume ',weightFile,' --dilation --eval --val_img_folder ',inputDir, ' --evalOutFilePostfix ', evalOutFilePostfix]);    
    cd(curDir)
elseif ~isempty(outDir)
    fd = fopen(fullfile(outDir,['Test_',evalOutFilePostfix,'_Epoch_-1.csv']),'wt');
    fclose(fd);
end