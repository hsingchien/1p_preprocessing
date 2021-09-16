function [ms,new_tstamp] = InterpoDropped(ms,tstamp)
% Input ms and timestamp, linearly interpolate dropped frames
% ms: CNMFE output or path to ms.mat
% tstamp: default Miniscope timestamp, nx3 matrix, columns are frame#, frame_time &
% buffer; or the path to the csv timestamp file

if ischar(ms)
    load(ms);
end
if ischar(tstamp)
    tstamp = csvread(tstamp, 1);
end

if size(tstamp,2) == 1 % when only the time(ms) column is fed
    tstamp = [transpose(0:1:(size(tstamp,1)-1)), tstamp]; 
end

% c1: frame#, c2, time(in ms), c3, buffer
% find the average inter frame interval
dif_tstamp = diff(tstamp(:,2));
avg_ft = mean([quantile(dif_tstamp,0.25), quantile(dif_tstamp,0.75)]);
frame_drop_at = find(round(dif_tstamp/avg_ft)>1);
frame_drop_num = round(dif_tstamp/avg_ft);
frame_drop_num = frame_drop_num(frame_drop_at);
if ~isempty(frame_drop_at)
    % generate true frame#
    for i = 1:length(frame_drop_at)
        tstamp(frame_drop_at(i)+1:end,1) = tstamp(frame_drop_at(i)+1:end,1)+(frame_drop_num(i)-1);
    end
    % start interpolation
    new_tstamp = interp1(tstamp(:,1),tstamp(:,2),0:1:tstamp(end,1));
    new_tstamp = reshape(new_tstamp,[],1);
    ms.RawTraces = interp1(tstamp(:,1), ms.RawTraces, 0:1:tstamp(end,1));
    ms.FiltTraces = interp1(tstamp(:,1),ms.FiltTraces,0:1:tstamp(end,1));
    ms.S = transpose(interp1(tstamp(:,1),transpose(ms.S),0:1:tstamp(end,1)));
    ms.DroppedFrame = setdiff(0:1:tstamp(end,1), tstamp(:,1));
    fprintf('these frames were dropped in recording and have been interpolated linearly\n');
    disp(ms.DroppedFrame);
else
    fprintf('no frame dropping issue. did nothing.\n');
    new_tstamp = tstamp(:,2);
end


end

