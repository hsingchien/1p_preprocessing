function [ms, ms_exp] = ParseMS(ms, f)
% parse ms to sep and exp
% f, end frame number to make the cut
if ischar(ms)
    load(ms);
end
ms_copy = ms;
if f(end) ~= size(ms_copy.FiltTraces,1);
    f = [f, size(ms_copy.FiltTraces,1)];
end
f = [0,f];

for i = 2:length(f)
    ms = ms_copy;
    ms.FiltTraces = ms.FiltTraces(f(i-1)+1:f(i),:);
    ms.RawTraces = ms.RawTraces(f(i-1)+1:f(i),:);
    ms.S = ms.S(:,f(i-1)+1:f(i));
    save(['ms_',num2str(i-1),'.mat'],'ms');
end

end

