function [handles,gotBBandCage] = loadBBandCageContours(imgDir,handles)
rows=288;
cols = 384;
BBandCageContours = fullfile(imgDir,'BBandCageContours.xml');
if isempty(handles)
    handles = struct();
end

handles.habCageX = [];
handles.habCageY = [];
handles.habCageMask = [];

handles.trialCageX = [];
handles.trialCageY = [];   
handles.trialCageMask = [];     

handles.habBbX = [];
handles.habBbY = [];
handles.habBbMask = [];

handles.trialBbX = [];
handles.trialBbY = [];  
handles.trialBbMask = [];
        
handles.stim1Line = [];
handles.stim2Line = [];

handles.habFrames = [];
handles.trialFrames = [];

gotBBandCage = false;
handles.tagFinished = false;
if exist(BBandCageContours,'file')
    gotBBandCage = true;
    s = readstruct(BBandCageContours);
    if isfield(s.habCage,'habCageX')
        handles.habCageX = s.habCage.habCageX;
        handles.habCageY = s.habCage.habCageY;
        handles.habCageMask = roipoly(zeros(rows,cols),handles.habCageX,handles.habCageY); 
    else
        gotBBandCage = false;
    end
    
    if isfield(s.trialCage,'trialCageX')
        handles.trialCageX = s.trialCage.trialCageX;
        handles.trialCageY = s.trialCage.trialCageY;   
        handles.trialCageMask = roipoly(zeros(rows,cols),handles.trialCageX,handles.trialCageY);        
    else
        gotBBandCage = false;
    end
    
    if isfield(s.habBB,'habBbX')
        handles.habBbX = s.habBB.habBbX;
        handles.habBbY = s.habBB.habBbY;
        handles.habBbMask = roipoly(zeros(rows,cols),handles.habBbX,handles.habBbY);
    else
        gotBBandCage = false;        
    end
    if isfield(s.trialBB,'trialBbX')
        handles.trialBbX = s.trialBB.trialBbX;
        handles.trialBbY = s.trialBB.trialBbY;  
        handles.trialBbMask = roipoly(zeros(rows,cols),handles.trialBbX,handles.trialBbY);
    else
        gotBBandCage = false;           
    end
          
    if isfield(s,'stim1LineX')
        handles.stim1Line = [s.stim1LineX(:),s.stim1LineY(:)]; 
    else
        gotBBandCage = false;           
    end        
    if isfield(s,'stim2LineX')
        handles.stim2Line = [s.stim2LineX(:),s.stim2LineY(:)];
    else
        gotBBandCage = false;           
    end      
        
    handles.habFrames=[s.habFrames.habStartFrame,s.habFrames.habEndFrame];
    handles.trialFrames=[s.trialFrames.trialStartFrame,s.trialFrames.trialEndFrame]; 
    
    handles.tagFinished = s.tagFinished;      
end