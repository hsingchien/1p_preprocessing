d = dir([pwd,'\**\']);
d = d([d(:).isdir]);
idx = [];
for i = 1:length(d)
    if contains(d(i).name,'XZ_run')
       idx = [idx,i];
    end
end

d = d(idx);
for i = 1:length(d)
    i
    d(i).folder
end


for id = 9:length(d) 
    full_path = [d(id).folder,'\',d(id).name];
    cd(full_path);
    pwd
    XZ_preprocessing();
    clearvars -except d id idx i full_path
end

