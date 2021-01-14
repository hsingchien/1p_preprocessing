function dallfolders = searchFolders(fname, directory)
%% search folders
% navigate to top-level directory first
% fname = 'Miniscope'; % change this to your folder name 
% dallfolders = dir([pwd,'\**\']); % list all paths under working directory

dallfolders = dir([directory,'\**\']); % list all paths under working directory
dallfolders = dallfolders([dallfolders(:).isdir]); % remove non-folder paths
idx = [];
for i = 1:length(dallfolders)
    if strcmp(dallfolders(i).name, fname)
       idx = [idx,i];
    end
end

dallfolders = dallfolders(idx); % now d only contains target folders 