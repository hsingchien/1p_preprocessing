%% get ready
clear all;
F = struct();
MouseN = 2; % # in this pair, corresponding to the number in behavior annotation (usually 1 is the marked one if annotated by XZ)
F.MouseN = MouseN;
FPS = 15;
nVideo = 3;
No = transpose(1:nVideo);
MouseID = cell(nVideo,1); MouseID(:) = {'TR185'}; 
% GenType = 'KO'; F.GenType = GenType;
date = cell(nVideo,1); date(:) = {'20220327'};
session = {'sep';'toy';'exp'};
time = {'16_47_31';'16_57_36';'17_14_03'};
% path for timestamps
filePath = {
    'E:\MiniscopeData(processed)\NewCage_free_dual\PV\2022_03_27_(AAV-PV)\TR185_TR170(m)\16_47_31_sep\Miniscope2_XZ185';
    'E:\MiniscopeData(processed)\NewCage_free_dual\PV\2022_03_27_(AAV-PV)\TR185_TR170(m)\16_57_36_toy\Miniscope2_XZ185';
    'E:\MiniscopeData(processed)\NewCage_free_dual\PV\2022_03_27_(AAV-PV)\TR185_TR170(m)\17_14_03_exp\Miniscope2_XZ185';
    };
% path for ms file and concatenated videos
% [~,ei] = regexp(filePath{1},'2021_\d*_\d*');
% msPath = filePath{1};
% msPath = [msPath(1:ei),'\',MouseID{1}];
msPath = 'E:\MiniscopeData(processed)\NewCage_free_dual\PV\2022_03_27_(AAV-PV)\TR185_TR170(m)\TR185\processed';
fileName = cell(nVideo,1); fileName(:) = {'msvideo_dFF.avi'};
F.ExperimentID = ['PairPV5_',date{1},'_F']; % change Pair#
F.ExperimentID
tempstr = strsplit(F.ExperimentID,'_');

saveName = [tempstr{1},'_',MouseID{1},'_',tempstr{2},'_F.mat'];
Ts = cell(1,nVideo);
qt = cell(1,nVideo);
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
%% MS
MS = cell(1,nVideo);
startFrame = ones(nVideo,1);
endFrame = [];
for i = 1:nVideo
   switch i
       case 1
           load([msPath,'\ms_sep.mat']);
       case 2
           load([msPath,'\ms_toy.mat']);
       case 3
           load([msPath,'\ms_exp.mat']);
       case 4
           load([msPath,'\ms_exp2.mat']);
       case 5
           load([msPath,'\ms_exp3.mat']);
       case 6
           load([msPath,'\ms_exp5.mat']);
       case 7
           load([msPath,'\ms_exp6.mat']);
   end 
   [ms, newt] = InterpoDropped(ms,Ts{i}.Ms); % interpolate dropped frames
   if isfield(ms,'cell_label')
       ms.goodCellVec = ms.cell_label;
       ms = rmfield(ms,'cell_label');
   end
   if isfield(ms,'vidObj')
       ms = rmfield(ms, 'vidObj');
   end
   
   MS{i} = ms;
   Ts{i}.Ms = newt; % linear-interpolation timestamp
   % also interpolate head orientation matrix
   interp_qt = interp1(qt{i}.data(:,1), qt{i}.data(:,2:end), newt);
   qt{i}.data = [newt,interp_qt];
   endFrame = [endFrame; size(ms.FiltTraces,1)];
end
F.MS = MS;
endFrame = cumsum(endFrame);
startFrame(2:end) = startFrame(2:end)+endFrame(1:end-1);
totalFrame = endFrame-startFrame+1;
duration = totalFrame/FPS;
fprintf('ms done\n');
%% videoInfo
F.videoInfo = table(No,MouseID,date,session,...
    time, filePath, fileName,startFrame,...
endFrame, totalFrame,duration);
F.AnimalID = MouseID{1};
fprintf('videoInfo constructed\n');
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
fprintf('timestamp constructed\n');
%% head orientation
F.HeadOrientation.qt = qt;
fprintf('head orientation constructed\n');
%% Behavior
Behavior = cell(1,nVideo);
Ac={};
for i = 1:nVideo
    temppath = strsplit(filePath{i},'\');
    behavpath = [strjoin(temppath(1:end-1), '\'),'\BehavCam_0'];
    if exist([behavpath,'\behavior.txt'])
        [B,A] = BehavStruExtract([behavpath,'\behavior.txt'], MouseN);
        Behavior{i} = B;
        Ac{i} = A;
        if contains(F.videoInfo.session{i},'toy')
            try 
                [B,A] = BehavStruExtract([behavpath,'\behavior.txt'], MouseN+2);
                Behavior{i}.Human = B;
                fprintf('session %d human behavior stream added for mouse %d\n', i, MouseN);
            catch ME
            end
        end
            
                
        fprintf('behavior of session %d constructed!\n',i);
    else
        fprintf('behavior annotation not found, session %d left blank\n',i);
    end
end
F.Annotation.annBD = Ac;
F.Behavior = Behavior;
%% add 'other' and reorder behavior field
all_behav_exp = {'attack','chasing','tussling','threaten','escape','defend',...
    'flinch','general-sniffing','sniff_face','sniff_genital','approach',...
    'follow','interaction', 'socialgrooming', 'mount','dig',...
    'selfgrooming', 'climb', 'exploreobj', 'biteobj', 'stand', 'nesting','human_interfere', 'other'};
all_behav_toy = {'attack', 'threaten', 'escape', 'flinch', 'defend', 'follow', 'attention', 'approach', 'general-sniffing',... 
    'mount', 'dig', 'selfgrooming', 'climb', 'exploreobj', 'biteobj', 'stand', ...
    'human_interfere', 'other'};

        for k = 1:length(F.Behavior)
            if contains(F.videoInfo.session{k},'toy')
                all_behav = all_behav_toy;
            else
                all_behav = all_behav_exp;
            end
            if ~isempty(F.Behavior{k})
                % add 'other'
                all_behav_vec = sum(vertcat(F.Behavior{k}.LogicalVecs{:}),1);
                other_logic = (all_behav_vec == 0);
                % find onset & offset (from 1)
                start = find(diff(other_logic)==1);
                eend = find(diff(other_logic)==-1)-1;
                if length(start) < length(eend)                    
                    start=[0,start];
                    fprintf('%d, %d, other start\n', i, j);
                elseif length(start) > length(eend);
                    eend=[eend,length(other_logic)-1];
                    fprintf('%d, %d, other end\n',i,j);
                end
                F.Behavior{k}.EventNames = [F.Behavior{k}.EventNames,'other'];
                F.Behavior{k}.OnsetTimes = [F.Behavior{k}.OnsetTimes,start];
                F.Behavior{k}.OffsetTimes = [F.Behavior{k}.OffsetTimes,eend];
                F.Behavior{k}.LogicalVecs = [F.Behavior{k}.LogicalVecs,other_logic];
                
                if ~ismember('tussling', F.Behavior{k}.EventNames) && contains(F.videoInfo.session{k},'exp')
                    F.Behavior{k}.EventNames = [F.Behavior{k}.EventNames,'tussling'];
                    F.Behavior{k}.OnsetTimes = [F.Behavior{k}.OnsetTimes,{[]}];
                    F.Behavior{k}.OffsetTimes = [F.Behavior{k}.OffsetTimes,{[]}];
                    F.Behavior{k}.LogicalVecs = [F.Behavior{k}.LogicalVecs, 0*F.Behavior{k}.LogicalVecs{1}];
                end
                if ismember('running', F.Behavior{k}.EventNames)
                    [~,i2] = ismember('running', F.Behavior{k}.EventNames);
                    F.Behavior{k}.EventNames{i2} = 'flinch';
                    fprintf('Pair %d has running instead of flinch\n', i);
                end
                
                % reorder
                [i1,i2] = ismember(all_behav, F.Behavior{k}.EventNames);
                F.Behavior{k}.EventNames = F.Behavior{k}.EventNames(i2);
                F.Behavior{k}.LogicalVecs = F.Behavior{k}.LogicalVecs(i2);
                F.Behavior{k}.OnsetTimes = F.Behavior{k}.OnsetTimes(i2);
                F.Behavior{k}.OffsetTimes = F.Behavior{k}.OffsetTimes(i2);
            end   
        end
%% Event
F.Event.VideoEnd = endFrame;
F.Event.VideoStart = startFrame;
F.Event.VideoFrame = totalFrame;
F.Event.VideoDuration = totalFrame/FPS;
fprintf('Event done.\n');
%% Event table
% Place Holder
%% save F structure
save(saveName,'F','-v7.3');
fprintf('save complete\n');

