%% home
xz_folder = 'D:/Dropbox/XZ_projects/ToolBoxes';
sep = '/';
%% lab
xz_folder = 'C:/Users/HonglabUser/Dropbox/XZ_projects/ToolBoxes';
sep = '/';
%% behavior analysis
addpath(genpath([xz_folder, sep, 'Behav_toolbox/']),...
    genpath([xz_folder, sep, 'mmread/']));

%% convert avi to seq

seqName = 'behavior.seq';
aviName = 'msvideo.avi';
seqIo([seqName],'frImgs',struct('codec','raw'),'aviName',[aviName])

%% annotate behavior
behavior_annotator;

%% construct behavior struct
annot_f = ''

A = behaviorData('load', annot_f);

%% construct experiment struct
expInfo = '';
ms_f1 = '';
ms_f2 = '';
E_struct = ExpstructGen(expInfo, ms_f1, ms_f2, A);