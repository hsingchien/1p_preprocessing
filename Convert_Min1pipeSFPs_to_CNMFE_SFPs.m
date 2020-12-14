% navigate to the folder contain all experiment folders
% each experiment folder contain these files: ***cellBounds.mat, ***dataMat
% cellBounds contain roi contours
% dataMat contains the extracted raw traces
%
% Change the directory
% This will pull out all *cellBounds.mat files (contains PCA/ICA
% footprints)
% cbfs = dir('D:\Xingjian\SH_subpop\CMK\**\*cellBounds.mat');
load('msCam_data_processed.mat');


sep = '\';
for i = 1:length(cbfs)
    
    load([cbfs(i).folder, sep, cbfs(i).name]);
    load([cbfs(i).folder, sep, strrep(cbfs(i).name, 'cellBounds', 'dataMat')]);
    disp(cbfs(i).name)
    
    
    
    ms = struct();

    ms.dirName = fileparts([cbfs(i).folder, sep, cbfs(i).name]);
    vsiz = size(imax);
    rois = reshape(roifn,vsiz(1), vsiz(2), []); 
    ms.SFPs = rois;
    ms.numNeurons = size(roifn,2);
    ms.FiltTraces = sigfn';
    ms.RawTraces = sigfn';
%     ms.CorrProj = zeros(size(cellBounds{1}));
    ms.numFrames = size(sigfn,2);
    ms.height = vsiz(1);
    ms.width = vsiz(2);
    ms.ds = 1;
    ms.Centroids = [];
    ms.roi_pos_ds = [];
    ms.roi_pos_full = [];
    ms.frameNum = 1:ms.numFrames;
    ms.vidObj = [];
    ms.shift = [];
    ms.analysis_duration = 0;
    ms.S = [];
    save([cbfs(i).folder, sep,'ms_PCA.mat'], 'ms');
    
end