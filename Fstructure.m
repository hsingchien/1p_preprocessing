%% get ready
clear all;
F = struct();
MouseN = 1; % # in this pair, corresponding to the number in behavior annotation (usually 1 is the marked one if annotated by XZ)
F.MouseN = MouseN;
FPS = 15;
nVideo = 2;
No = transpose(1:nVideo);
MouseID = cell(nVideo,1); MouseID(:) = {'XZ70'}; 
date = cell(nVideo,1); date(:) = {'20210402'};
session = transpose(1:nVideo);
time = {'14_00_38'; '14_16_01'};
filePath = {'E:\MiniscopeData(processed)\NewCage_free_dual\CMK_vs_CMK\XZ71_XZ70(m)\2021_04_02\14_00_38_sep\Miniscope1_XZ70';...
    'E:\MiniscopeData(processed)\NewCage_free_dual\CMK_vs_CMK\XZ71_XZ70(m)\2021_04_02\14_16_01_exp\Miniscope1_XZ70'};
fileName = {'msvideo_dFF.avi'; 'msvideo_dFF.avi'};
F.ExperimentID = ['PairC1_',date{1},'_F']; % change Pair#
F.ExperimentID
tempstr = strsplit(F.ExperimentID,'_');

saveName = [tempstr{1},'_',MouseID{1},'_',tempstr{2},'_F.mat'];
startFrame = ones(nVideo,1);
endFrame = [];
for i = 1:nVideo
    vid = VideoReader([filePath{i},'\',fileName{i}]);
    endFrame = [endFrame; vid.NumFrames];
end
totalFrame = endFrame;
duration = totalFrame/FPS;
Ts = cell(1:nVideo);
qt = cell(1:nVideo);
for i = 1:nVideo
    if exist([filePath{i},'\','timeStamps_ds.csv'])
        temp = csvread([filePath{i},'\','timeStamps_ds.csv'],1);
    else
        temp = csvread([filePath{i},'\','timeStamps.csv'],1);
    end
    if exist([filePath{i},'\','headOrientation_ds.csv'])
        headori = csvread([filePath{i},'\','headOrientation_ds.csv'],1);
    else
        headori = csvread([filePath{i},'\','headOrientation.csv'],1);
    end
    qt{i}.data = headori;
    temppath = strsplit(filePath{i},'\');
    behavpath = [strjoin(temppath(1:end-1), '\'),'\BehavCam_0'];
    bets = csvread([behavpath,'\timeStamps.csv'],1);
    Ts{i}.Bv = bets(:,2);
    Ts{i}.Ms = temp(:,2);
    Ts{i}.Qt = headori(:,1);
end

%% videoInfo
F.videoInfo = table(No,MouseID,date,session,...
    time, filePath, fileName,startFrame,...
endFrame, totalFrame,duration);

%% MS
MS = cell(1,nVideo);
for i = 1:nVideo
   load([filePath{i},'\ms_cleaned.mat']);
   if isfield(ms,'cell_label')
       ms.goodCellVec = ms.cell_label;
       ms = rmfield(ms,'cell_label');
   end
   MS{i} = ms;
end
F.MS = MS;
%% align timestamps
F.TimeStamp.Ts = Ts;
mapTs = cell(1,nVideo);
for i = 1:nVideo
    [~, B2M] = TStampAlign(Ts{i}.Ms,Ts{i}.Bv);
    mapTs{i}.B2M = B2M;
    [~, M2B] = TStampAlign(Ts{i}.Bv, Ts{i}.Ms);
    mapTs{i}.M2B = M2B;
end
F.TimeStamp.mapTs = mapTs;
%% head orientation
F.HeadOrientation.qt = qt;
%% Behavior
Behavior = cell(1,nVideo);
A={};
for i = 1:nVideo
    temppath = strsplit(filePath{i},'\');
    behavpath = [strjoin(temppath(1:end-1), '\'),'\BehavCam_0'];
    if exist([behavpath,'\behavior.txt'])
        [B,A] = BehavStruExtract([behavpath,'\behavior.txt'], MouseN);
        Behavior{i} = B;
    end
end
F.Annotation.annBD = A;
F.Behavior = Behavior;
%% Event
F.Event.VideoEnd = endFrame;
F.Event.VideoStart = startFrame;
F.Event.VideoFrame = totalFrame;
F.Event.VideoDuration = totalFrame/FPS;
%% Event table
% Place Holder
%% save F structure
save(saveName,'F');

