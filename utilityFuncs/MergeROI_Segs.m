function ms = MergeROI_Segs(ms,ml,tl)
% Combined session processing 1 cell could have spatial shift over time.
% CNMFE could pick duplicated signals. This function merges these
% duplicated ROIs by concate them at specified time point. Input: ms,
% string, directory of ms.mat. ml: merge list, nx2, each row being the IDs
% of the 2 rois you want to merge. tl: at what frame do you want to merge
% them. Output ms will have merged ROIs added at the end and labeled as good
% cells and origianl 2 ROIs labeled as bad cells.
if length(tl) == 1
    tl = ones([1,size(ml,1)]) * tl;
end

for i = 1:size(ml,1)
    c1 = ms.FiltTraces(:, ml(i,1));
    c2 = ms.FiltTraces(:, ml(i,2));
    firstc = ml(i,1);
    secondc = ml(i,2);
    newcF = [ms.FiltTraces(1:tl(i),firstc);ms.FiltTraces(tl(i)+1:end,secondc)];
    newcR = [ms.RawTraces(1:tl(i), firstc); ms.RawTraces(tl(i)+1:end,secondc)];
    newSFP = ms.SFPs(:,:,firstc) + ms.SFPs(:,:,secondc);
    newcS = [ms.S(firstc, 1:tl(i)), ms.S(secondc,tl(i)+1:end)];
    ms.FiltTraces = cat(2, ms.FiltTraces, newcF);
    ms.RawTraces = cat(2, ms.RawTraces, newcR);
    ms.SFPs = cat(3, ms.SFPs, newSFP);
    ms.S = cat(1,ms.S,newcS);
    ms.cell_label(ml(i,:)) = 0;
    ms.cell_label = [ms.cell_label;1];
    ms.numNeurons = ms.numNeurons + 1;
end
try
    ms = rmfield(ms,'centroids_xz');
catch 
    warning('failed to rmv field centroids_xz');
end
    
end

