function ms = msNormCorre(ms,isnonrigid,crop);
% Performs fast, rigid registration (option for non-rigid also available).
% Relies on NormCorre (Paninski lab). Rigid registration works fine for
% large lens (1-2mm) GRIN lenses, while non-rigid might work better for
% smaller lenses. Ideally you want to compare both on a small sample before
% choosing one method or the other.
% Original script by Eftychios Pnevmatikakis, edited by Guillaume Etter


warning off all

%% Auto-detect operating system
if ispc
    separator = '\'; % For pc operating systems
else
    separator = '/'; % For unix (mac, linux) operating systems
end


%% Filtering parameters
gSig = 7/ms.ds;
gSiz = 17/ms.ds;
psf = fspecial('gaussian', round(2*gSiz), gSig);
ind_nonzero = (psf(:)>=max(psf(:,1)));
psf = psf-mean(psf(ind_nonzero));
psf(~ind_nonzero) = 0;
% bound = round(ms.height/(2*ms.ds));
bound = 0;

template = [];

writerObj = VideoWriter([ms.dirName separator ms.analysis_time separator 'msvideo_corrected.avi'],'Grayscale AVI');
open(writerObj);

ms.shifts = [];
ms.meanFrame = [];
if isfield(ms, 'vName')
    ms.numFiles = 1;
end


for video_i = 1:ms.numFiles;
    if isfield(ms, 'vName')
        name = ms.vName;
    else
        name = [ms.vidObj{1, video_i}.Path separator ms.vidObj{1, video_i}.Name];
    end
    disp(['Registration on: ' name]);
    
    % read data and convert to single
    Yf = read_file(name);
    Yf = single(Yf);
%     Yf = downsample_data(Yf,'space',1,ms.ds,1);
    
    Y = imfilter(Yf,psf,'symmetric');
    [d1,d2,T] = size(Y);
      
    % Setting registration parameters (rigid vs non-rigid)
    if isnonrigid
        disp('Non-rigid motion correction...');
    options = NoRMCorreSetParms('d1',d1,'d2',d2,'bin_width',50, ...
    'grid_size',[32,32]*2,'mot_uf',4,'correct_bidir',false, ...
    'overlap_pre',8,'overlap_post',8,'max_shift',10);
    else
        disp('Rigid motion correction...');
    options = NoRMCorreSetParms('d1',d1-bound,'d2',d2-bound,'bin_width',200,'max_shift',20,'iter',1,'correct_bidir',false);
    end
    
    %% register using the high pass filtered data and apply shifts to original data
    if isempty(template);
        [M1,shifts1,template] = normcorre(Y(bound/2+1:end-bound/2,bound/2+1:end-bound/2,:),options); % register filtered data
        % exclude boundaries due to high pass filtering effects
    else
        [M1,shifts1,template] = normcorre(Y(bound/2+1:end-bound/2,bound/2+1:end-bound/2,:),options,template); % register filtered data
    end
    
    Mr = apply_shifts(Yf,shifts1,options,bound/2,bound/2); % apply shifts to full dataset
    % apply shifts on the whole movie    
    if ~isempty(crop)
        ybound = min(size(Mr,1), crop(2)+crop(4)+1);
        xbound = min(size(Mr,2), crop(1)+crop(3)+1);
        writeVideo(writerObj,uint8(imresize(Mr(crop(2)+1:ybound, crop(1)+1:xbound,:),1/ms.ds,'Method','box')));
    else
        writeVideo(writerObj,uint8(Mr));
    end
    %% compute metrics
    [cYf,mYf,vYf] = motion_metrics(Yf,options.max_shift); 
    [cM1f,mM1f,vM1f] = motion_metrics(Mr,options.max_shift);
    
    if video_i == 1;
    ms.meanFrame = mM1f;
    else;
    ms.meanFrame = (ms.meanFrame + mM1f)./2;
    end
    corr_gain = cYf./cM1f*100;
    
    ms.shifts{video_i} = shifts1;
       
end
ms.crop = crop;
close(writerObj);

end