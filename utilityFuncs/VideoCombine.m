function vmat_total = VideoCombine(dir_f, vtype, sa)
% input: 
% VideoCombine(dir_f, vtype, sa)
% dir_f, directory of target video files, default .avi files named in order
% starting from 0. 
% sa, save or not, default false

if nargin < 2
    vtype = 'm';
    sa = false;
elseif nargin < 3
    sa = false;
end

if ~(strcmp(vtype, 'b') | strcmp(vtype, 'm'))
    error('invalid video type. b for behavior, m for miniscope');
end

    %% set the useful constants
    cchannel = 3;
    %%
    all_v = dir(strcat(dir_f, '/*.avi')); % all_v is a numFile x 1 struct with field name, folder, date, bytes, isdir, datenum
    % sort files by name, 0, 1, 2, 3, etc.
    avi_cell = struct2cell(all_v); % convert to cell, 6 x numFile
    avi_names = avi_cell(find(strcmp(fields(all_v), 'name')), :);
    avi_id_list = [];
    for i = 1:length(avi_names)
       temp = split(avi_names{i}, '.');
       fname = temp{1};
       digit_i = regexp(fname, '\d*');
       avi_id_list = [avi_id_list, str2num(fname(digit_i(end):end))];
    end
    [~, forder] = sort(avi_id_list);
    all_v = all_v(forder); % reorder the struct to the video order
    avi_names = avi_names(forder);
    %% start read each avi by order and combine them into 1 giant .mat file
    %% preallocate the array
    v = VideoReader(strcat(dir_f, '/', avi_names{1}));
    xwidth = v.Width;
    ywidth = v.Height;
    frame_per_file = v.NumFrames;
    vmat_total = zeros(ywidth, xwidth, frame_per_file * length(avi_names), 'uint8');
    total_f = 0;
    fprintf('combining %d video files...\n', length(avi_names));
    fprintf('allocated %d GBs of memory...\n', prod(size(vmat_total))/1024/1024/1024);
    for i = 1:length(avi_names)
       tic;
       v = VideoReader(strcat(dir_f, '/', avi_names{i}));
       vmat = read(v);  % default last dimension is time 
       if strcmp(vtype, 'b')
           vmat_bw = squeeze(0.2989 * vmat(:,:,1,:) + 0.5870 * vmat(:,:,2,:) + 0.1140 * vmat(:,:,3,:));
       elseif strcmp(vtype, 'm')
           vmat_bw = squeeze(vmat(:,:,1,:));  % in this case, miniscope all 3 channels are the same 
       end
       vmat_total(:,:,total_f+1 : total_f+size(vmat_bw, 3)) = vmat_bw;
       % remove unused mat frames
       if i == length(avi_names)
          vmat_total(:,:,total_f+size(vmat_bw,3)+1:frame_per_file * length(avi_names)) = [];
       end
       total_f = total_f + size(vmat_bw, 3);
       fprintf('%d of %d files processed...\n', i, length(avi_names));
       fprintf('%.2f s remaining...\n', (length(avi_names) - i)*toc);
       delete(v);   
    end
    if sa
        fprintf('saving to .mat file at %s...\n', dir_f);
        save(strcat(dir_f, '/video_total.mat'), 'vmat_total');
    else
        fprintf('combined video not saved\n');
    end
end


