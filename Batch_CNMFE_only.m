% This Script does the following:
% Input RAW videos (already converted from FFV1 to compatible codecs if necessary)
% First do motion correction using non reigid Normcorre, spatial downsample
% by 2(default). Corrected video is saved as msvideo_corrected.avi. Then
% FFT (using ImageJ) on motion corrected & downsampled video. This part of 
% the code has to be run in base workspace. At last, CNMFE on the FFT video. 
% Reject cells with CellScreener after this. 


%% Set paths to your raw videos and options for normcorre and fft
% IMPORTANT: Before you run, make sure the videos are visually consistent. 
% Bad frames caused by miniscope failure should be removed before starting 
% this script, otherwise CNMFE will throw errors.
RawInputDir = {

    

    };

%% cnmfe parameters
CNMFE_options = struct(...
'Fs', 15,... % frame rate
'tsub', 1,... % temporal downsampling factor
'gSig', 3,... % pixel, gaussian width of a gaussian kernel for filtering the data. 0 means no filtering
'gSiz', 12,... % pixel, neuron diameter
'nk', 3,...
...% background model
'bg_model', 'ring',... % model of the background {'ring', 'svd'(default), 'nmf'}
'nb', 1,...             % number of background sources for each patch (only be used in SVD and NMF model)
'ring_radius', 16,...  % when the ring model used, it is the radius of the ring used in the background model.
...% merge
'merge_thr', 0.65,...
'merge_thr_spatial', [0.5,0.1,-Inf],...% thresholds for merging neurons; [spatial overlap ratio, temporal correlation of calcium traces, spike correlation]
'dmin', 3,... % minimum distances between two neurons. it is used together with merge_thr
...% initialize
'min_corr', 0.75,... % minimum local correlation for a seeding pixel, default 0.8, cmk 0.75
'min_pnr', 21,... % minimum peak-to-noise ratio for a seeding pixel, cmk 21, gaba 12
...% residual
'min_corr_res', 0.7,... % cmk 0.7 gaba 0.7
'min_pnr_res', 19); % cmk 19 gaba 10
    %% CNMFE on FFT output
 for i = 1:length(RawInputDir)
    cd(RawInputDir{i});
    fprintf(pwd);
    clearvars -except RawInputDir i CNMFE_options;
    vName = 'msvideo_dFF.avi';
    XZ_CNMFE_batch(pwd, vName, CNMFE_options);
%     FFTTraces('msvideo_dFF.avi', 'ms.mat',0.8,true);
end