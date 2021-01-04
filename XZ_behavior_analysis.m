%% home
xz_folder = 'D:/Dropbox/XZ_projects/ToolBoxes';
sep = '/';
%% lab
xz_folder = 'C:/Users/HonglabUser/Dropbox/XZ_projects/ToolBoxes';
sep = '/';
%% behavior analysis
addpath(genpath([xz_folder, sep, 'Behav_toolbox/']),...
    genpath([xz_folder, sep, 'mmread/']));
%% utility funcs home
addpath(genpath('D:/Matlab Repo/XZ_funkies'));
%% utility funcs lab
addpath(genpath('D:/Xingjian/Repositories/XZ_funkies'));
%% combine into 1 video file
VideoCombine(pwd, 'b', true, 'avi');


%% convert avi to seq

seqName = 'behavior.seq';
aviName = 'behav_video.avi';
seqIo([seqName],'frImgs',struct('codec','raw'),'aviName',[aviName]);

%% annotate behavior
behavior_annotator;

%% construct behavior struct
annot_f = 'behaviorAnnot.txt'

A = behaviorData('load', annot_f);

%% construct experiment struct
expInfo = 'XZ35_mouse_present';
ms_f1 = strrep('D:\UCLA_data\Miniscope\2020_12_30\XZ35\17_08_56\Miniscope\raw\ms\ms.mat','\','/');
ms_f2 = strrep('','\','/');
E_struct = ExpstructGen(expInfo, ms_f1, ms_f2, A);
%% Plot all cells with behavior patched
PlotSelectedCells( E_struct{1}, 100:200, false)