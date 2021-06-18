rTraces = ms.RawTraces;
fTraces = ms.FiltTraces;
% 7332 - 7338
fstart = 7331;
fend =7343;
rTraces(fstart:fend,:) = (rTraces(fend+1,:) - rTraces(fstart-1,:)) /(fend-fstart+1) .* transpose(1:(fend-fstart+1)) + rTraces(fstart-1,:);
fTraces(fstart:fend,:) = (fTraces(fend+1,:) - fTraces(fstart-1,:)) /(fend-fstart+1) .* transpose(1:(fend-fstart+1)) + fTraces(fstart-1,:);

