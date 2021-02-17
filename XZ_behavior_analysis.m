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
seqIo([seqName],'frImgs',struct('codec','png'),'aviName',[aviName]);

%% annotate behavior
behavior_annotator;

%% construct behavior struct
annot_f = 'behavior.txt'

A = behaviorData('load', annot_f);

%% construct experiment struct
expInfo = {'SH19_HCsep2','SH21_HCsep1'};
ms_f1 = strrep('E:\MiniscopeData(processed)\NewCage_free_dual\DW22_XZ46\11_39_46_01_21_21\Miniscope_1_DW22\ms.mat','\','/');
ms_f2 = strrep('E:\MiniscopeData(processed)\NewCage_free_dual\DW22_XZ46\11_39_46_01_21_21\Miniscope_0_XZ46\ms.mat','\','/');
E_struct = ExpstructGen(expInfo, ms_f1, ms_f2, A);save(strrep('E:\MiniscopeData(processed)\NewCage_free_dual\DW22_XZ46\11_39_46_01_21_21\E_struct.mat','\','/'),'E_struct');
%% Plot all cells with behavior patched
PlotSelectedCells(E_struct{1}, 1:100, false)