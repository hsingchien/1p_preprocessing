%% To use this batch processing script:
% all your avi files (make sure all are gray avis) are organized in
% experiment_directory/**/my_folder. my_folder can be any folder name, as long
% as it is consistant across experiments, and can be uniquely found. it can be in
% subfolder of any order, the script will do a recursive search and return 
% all directories matching the folder name. 


%% search ms folders
% **navigate to top-level directory first
dallfolders = searchFolders('msCam_raw', pwd)

%% check paths
for i = 1:length(dallfolders)
    fprintf('%d, %s, %s \n', i, dallfolders(i).folder, dallfolders(i).name); % list all avi pathes, check before run!
end

%% optional transcode all ff1 avi to raw avi
% converts for all avi files in all dir, incl beh, outputs to folder 'raw'
convert_msCam1({pwd})

%% optional renaming, prepend 'msCam' and start at 1 to be compatible w/ downstream pipeline
% expects format eg "0.avi"
for id = 1:length(dallfolders) 
    full_path = [dallfolders(id).folder,'\',dallfolders(id).name];
    cd(full_path)
    dfolder = dir(full_path);
    aviidx = find(endsWith({dfolder.name},'.avi')==1);
    originalfnames = [0:length(aviidx)-1];
    for ii = 1:length(aviidx)
        movefile([num2str(originalfnames(ii)) '.avi'], ['msCam' num2str(ii) '.avi']);
    end
end

%% optional convert to grayscale
for id = 1:length(dallfolders) 
    full_path = [dallfolders(id).folder,'\',dallfolders(id).name];
    aviRGBtoGray(full_path, strcat(full_path, '/ms/'), 'msCam', ''); % put in '/ms/' subfolder; don't prepend
end

%% optional move to msCam to be compatible w/ old pipeline

%% search converted folders
% navigate to top-level directory first
dgrayfolders = searchFolders('ms', pwd)

for i = 1:length(dgrayfolders)
    fprintf('%d, %s, %s \n', i, dgrayfolders(i).folder, dgrayfolders(i).name); % list all avi pathes, check before run!
end

%% Run batch preprocessing 
% if out of memory error, resume where the error happens
for id = 2:length(dgrayfolders) % note skipping first
    full_path = [dgrayfolders(id).folder,'\',dgrayfolders(id).name];
    cd(full_path);
    pwd
    XZ_preprocessing_batch();
    close all;
    clearvars -except d id idx i full_path dgrayfolders
end

