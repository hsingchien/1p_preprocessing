%% To use this batch processing script:
% all your avi files (make sure all are gray avis) are organized in
% experiment_directory/**/my_folder. my_folder can be any folder name, as long
% as it is consistant across experiments, and can be uniquely found. it can be in
% subfolder of any order, the script will do a recursive search and return all
% directories containing the folder name. 




%% search folders
fname = 'XZ_run'; % change this to your folder name 
d = dir([pwd,'\**\']); % list all pathes under working directory
d = d([d(:).isdir]); % remove non-folder pathes
idx = [];
for i = 1:length(d)
    if contains(d(i).name, fname)
       idx = [idx,i];
    end
end

d = d(idx); % now d only contains avi folders 

for i = 1:length(d)
    fprintf('%d, %s', i, d(i).folder); % list all avi pathes, check before run!
end
%% Run batch preprocessing 

for id = 9:length(d) 
    full_path = [d(id).folder,'\',d(id).name];
    cd(full_path);
    pwd
    XZ_preprocessing_batch();
    clearvars -except d id idx i full_path
end

