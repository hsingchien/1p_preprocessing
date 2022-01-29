Fversion = '20220128';
for i = 1:length(allPairs)
    for j = 1:2
        allPairs{i}{j}.Fversion = Fversion;
    end
end


for i = 1:length(allPairs)
    M1 = allPairs{i}{1};
    M2 = allPairs{i}{2};
    
    M1Ts = M1.TimeStamp.Ts;
    M2Ts = M2.TimeStamp.Ts;
    
    for m = 1:length(M1Ts)
        M1tstamp = M1Ts{m}.Ms;
        M2tstamp = M2Ts{m}.Ms;
        
        [~, M1toM2] = TStampAlign(M2tstamp,M1tstamp);
        [~, M2toM1] = TStampAlign(M1tstamp,M2tstamp);
        M1.TimeStamp.mapTs{m}.M1toM2 = M1toM2;
        M1.TimeStamp.mapTs{m}.M2toM1 = M2toM1;
        M2.TimeStamp.mapTs{m}.M1toM2 = M1toM2;
        M2.TimeStamp.mapTs{m}.M2toM1 = M2toM1;
        
        [~,tempMap] = TStampAlign(M1.TimeStamp.Ts{m}.Bv,M1.TimeStamp.Ts{m}.Ms);
        M1.TimeStamp.mapTs{m}.M2B = tempMap;
        [~,tempMap] = TStampAlign(M1.TimeStamp.Ts{m}.Ms,M1.TimeStamp.Ts{m}.Bv);
        M1.TimeStamp.mapTs{m}.B2M = tempMap;
        [~,tempMap] = TStampAlign(M2.TimeStamp.Ts{m}.Bv,M2.TimeStamp.Ts{m}.Ms);
        M2.TimeStamp.mapTs{m}.M2B = tempMap;
        [~,tempMap] = TStampAlign(M2.TimeStamp.Ts{m}.Ms,M2.TimeStamp.Ts{m}.Bv);
        M2.TimeStamp.mapTs{m}.B2M = tempMap;
    end
    allPairs{i}{1} = M1;
    allPairs{i}{2} = M2;
end
%%
% disply flatline good cells and set them to bad
for i = 1:length(allPairs)
    for j = 1:2
        flatline_cell_id = [];
        for m = 1:length(allPairs{i}{j}.MS)
            c_ms = allPairs{i}{j}.MS{m};
            filtT = c_ms.FiltTraces;
            cid = find(sum(filtT,1)==0);
            if ~isempty(cid)
               fprintf('pair %d, animal %d, session %d\n',i,j,m);
               fprintf('cell %d\n',cid);
               flatline_cell_id = [flatline_cell_id, cid];
                
            end
        end
        for m = 1:length(allPairs{i}{j}.MS)
            allPairs{i}{j}.MS{m}.goodCellVec(flatline_cell_id) = 0;
            allPairs{i}{j}.MS{m}.goodCellVec = logical(allPairs{i}{j}.MS{m}.goodCellVec);
        end
    end
end



%%

for i = 1:length(allPairs)
    for j = 1:2
        for m = 1:length(allPairs{i}{j}.TimeStamp.Ts)
            
           if length(allPairs{i}{j}.TimeStamp.Ts{m}.Bv)~= length(allPairs{i}{j}.TimeStamp.mapTs{m}.M2B)
               fprintf([num2str(i),',', num2str(j),',', num2str(m),'M2B\n']);
           end
           if length(allPairs{i}{j}.TimeStamp.Ts{m}.Ms)~= length(allPairs{i}{j}.TimeStamp.mapTs{m}.B2M)
               fprintf([num2str(i),',', num2str(j),',', num2str(m),'B2M\n']);
           end
        end
        
    end
end
%% truncate to make sure timestamps strictly matches video length
for i = 1:length(allPairs)
    for j = 1:2
        session_length = allPairs{i}{j}.videoInfo.totalFrame;
        session_length1 = allPairs{i}{1}.videoInfo.totalFrame;
        session_length2 = allPairs{i}{2}.videoInfo.totalFrame;
        for m = 1:length(session_length)
            allPairs{i}{j}.TimeStamp.mapTs{m}.B2M = allPairs{i}{j}.TimeStamp.mapTs{m}.B2M(1:min(session_length(m),length(allPairs{i}{j}.TimeStamp.mapTs{m}.B2M)));
            allPairs{i}{j}.TimeStamp.mapTs{m}.M1toM2 = allPairs{i}{j}.TimeStamp.mapTs{m}.M1toM2(1:min(session_length2(m),length(allPairs{i}{j}.TimeStamp.mapTs{m}.M1toM2)));
            allPairs{i}{j}.TimeStamp.mapTs{m}.M2toM1 = allPairs{i}{j}.TimeStamp.mapTs{m}.M2toM1(1:min(session_length1(m),length(allPairs{i}{j}.TimeStamp.mapTs{m}.M2toM1)));
        end
    end
end
%% add 'other' and reorder behavior field
all_behav_exp = {'attack','chasing','tussling','threaten','escape','defend',...
    'flinch','general-sniffing','sniff_face','sniff_genital','approach',...
    'follow','interaction', 'socialgrooming', 'mount','dig',...
    'selfgrooming', 'climb', 'exploreobj', 'biteobj', 'stand', 'nesting','human_interfere', 'other'};
all_behav_toy = {'attack', 'threaten', 'escape', 'flinch', 'defend', 'follow', 'attention', 'approach', 'general-sniffing',... 
    'mount', 'dig', 'selfgrooming', 'climb', 'exploreobj', 'biteobj', 'stand', ...
    'human_interfere', 'other'}; 

for i = 1:length(allPairs)
    for j = 1:2
        for k = 1:length(allPairs{i}{j}.Behavior)
            if contains(allPairs{i}{j}.videoInfo.session{k},'toy')
                all_behav = all_behav_toy;
            else
                all_behav = all_behav_exp;
            end
            if ~isempty(allPairs{i}{j}.Behavior{k})
                % add 'other'
                all_behav_vec = sum(vertcat(allPairs{i}{j}.Behavior{k}.LogicalVecs{:}),1);
                other_logic = (all_behav_vec == 0);
                % find onset & offset (from 1)
                start = find(diff(other_logic)==1);
                eend = find(diff(other_logic)==-1)-1;
                if length(start) < length(eend)                    
                    start=[0,start];
                    fprintf('%d, %d, other start\n', i, j);
                elseif length(start) > length(eend);
                    eend=[eend,length(other_logic)-1];
                    fprintf('%d, %d, other end\n',i,j);
                end
                allPairs{i}{j}.Behavior{k}.EventNames = [allPairs{i}{j}.Behavior{k}.EventNames,'other'];
                allPairs{i}{j}.Behavior{k}.OnsetTimes = [allPairs{i}{j}.Behavior{k}.OnsetTimes,start];
                allPairs{i}{j}.Behavior{k}.OffsetTimes = [allPairs{i}{j}.Behavior{k}.OffsetTimes,eend];
                allPairs{i}{j}.Behavior{k}.LogicalVecs = [allPairs{i}{j}.Behavior{k}.LogicalVecs,other_logic];
                
                if ~ismember('tussling', allPairs{i}{j}.Behavior{k}.EventNames) && contains(allPairs{i}{j}.videoInfo.session{k},'exp')
                    allPairs{i}{j}.Behavior{k}.EventNames = [allPairs{i}{j}.Behavior{k}.EventNames,'tussling'];
                    allPairs{i}{j}.Behavior{k}.OnsetTimes = [allPairs{i}{j}.Behavior{k}.OnsetTimes,{[]}];
                    allPairs{i}{j}.Behavior{k}.OffsetTimes = [allPairs{i}{j}.Behavior{k}.OffsetTimes,{[]}];
                    allPairs{i}{j}.Behavior{k}.LogicalVecs = [allPairs{i}{j}.Behavior{k}.LogicalVecs, 0*allPairs{i}{j}.Behavior{k}.LogicalVecs{1}];
                    fprintf('Pair %d added tussling.\n', i)
                end
                if ismember('running', allPairs{i}{j}.Behavior{k}.EventNames)
                    [~,i2] = ismember('running', allPairs{i}{j}.Behavior{k}.EventNames);
                    allPairs{i}{j}.Behavior{k}.EventNames{i2} = 'flinch';
                    fprintf('Pair %d has running instead of flinch\n', i);
                end
                
                % reorder
                [i1,i2] = ismember(all_behav, allPairs{i}{j}.Behavior{k}.EventNames);
                allPairs{i}{j}.Behavior{k}.EventNames = allPairs{i}{j}.Behavior{k}.EventNames(i2);
                allPairs{i}{j}.Behavior{k}.LogicalVecs = allPairs{i}{j}.Behavior{k}.LogicalVecs(i2);
                allPairs{i}{j}.Behavior{k}.OnsetTimes = allPairs{i}{j}.Behavior{k}.OnsetTimes(i2);
                allPairs{i}{j}.Behavior{k}.OffsetTimes = allPairs{i}{j}.Behavior{k}.OffsetTimes(i2);
            end
         end
    end
end

%% timestamp interpolation, adjust timestamps accordingly.
for i = 1:length(allPairs)
    for j = 1:2
        numframe = [];
        for k = 1:length(allPairs{i}{j}.MS)
               fprintf('pair %d, animal %d, id %s, ms %d\n', i,j,allPairs{i}{j}.AnimalID,k)
               ms = allPairs{i}{j}.MS{k};
               Ts = allPairs{i}{j}.TimeStamp.Ts{k};
               qt = allPairs{i}{j}.HeadOrientation.qt{k};
               if length(Ts.Ms)~=length(ms.FiltTraces)
                   Ts.Ms = Ts.Ms(1:length(ms.FiltTraces));
               end
               [ms, newt] = InterpoDropped(ms,Ts.Ms); % interpolate dropped frames
               Ts.Ms = newt; % linear-interpolation timestamp
               Ts.Qt = newt; % linear-interpolation timestamp
               % also interpolate head orientation matrix
               interp_qt = interp1(qt.data(:,1), qt.data(:,2:end), newt);
               qt.data = [newt,interp_qt];
               allPairs{i}{j}.HeadOrientation.qt{k} = qt;
               allPairs{i}{j}.MS{k} = ms;
               % map
               allPairs{i}{j}.TimeStamp.Ts{k} = Ts;
               
               
               [~, B2M] = TStampAlign(allPairs{i}{j}.TimeStamp.Ts{k}.Ms,allPairs{i}{j}.TimeStamp.Ts{k}.Bv);
               allPairs{i}{j}.TimeStamp.mapTs{k}.B2M = B2M;
               [~, M2B] = TStampAlign(allPairs{i}{j}.TimeStamp.Ts{k}.Bv, allPairs{i}{j}.TimeStamp.Ts{k}.Ms);
               allPairs{i}{j}.TimeStamp.mapTs{k}.M2B = M2B;
               numframe = [numframe, length(newt)];

        end
        startframe = cumsum(numframe')+1;
        startframe = [1;startframe(1:end-1)];
        endframe = cumsum(numframe');
        allPairs{i}{j}.videoInfo.endFrame = endframe;
        allPairs{i}{j}.videoInfo.startFrame = startframe;
        allPairs{i}{j}.videoInfo.totalFrame = numframe';
        allPairs{i}{j}.Event.VideoEnd = endframe;
        allPairs{i}{j}.Event.VideoStart = startframe;
        allPairs{i}{j}.Event.VideoFrame = numframe';
        allPairs{i}{j}.Event.VideoDuration = numframe'/15;
    end
end
   %% display good cell number
for i = 1:length(allPairs)
    for j = 1:2
        fprintf('pair %d, animal %d, id %s cell %d\n', i, j, allPairs{i}{j}.AnimalID, sum(allPairs{i}{j}.MS{1}.goodCellVec));
    end
end
%% display genotypes
for i = 1:length(allPairs)
    for j = 1:2
        fprintf('pair %d, animal %d, id %s genotype %s\n', i, j, allPairs{i}{j}.AnimalID, allPairs{i}{j}.GenType);
    end
end


%% find ms and tstamp inconsistancy
for i = 1:length(allPairs)
    for j = 1:2
        for k = 1:length(allPairs{i}{j}.MS)
           msl = size(allPairs{i}{j}.MS{k}.FiltTraces,1);
           tsl = length(allPairs{i}{j}.TimeStamp.Ts{k}.Ms);
           if msl~=tsl
               fprintf('pair %d, animal %d, id %s, trial %d, ms length %d, timestamp length %d\n', i, j, allPairs{i}{j}.AnimalID,k,msl,tsl);
           end
        end
    end
end
%% recalculate pcc and save it in a map container
cor_values = containers.Map()
for i =1:length(allPairs)
    this_cor = [];
    PairID = ['Pair',num2str(i)];
    for k = 1:length(allPairs{i}{1}.MS)
        filt1 = mean(zscore(allPairs{i}{1}.MS{k}.FiltTraces(:,find(allPairs{i}{1}.MS{k}.goodCellVec))),2);
        filt2 = mean(zscore(allPairs{i}{2}.MS{k}.FiltTraces(:,find(allPairs{i}{2}.MS{k}.goodCellVec))),2);
        M1toM2 = allPairs{i}{1}.TimeStamp.mapTs{k}.M1toM2;
        M2toM1 = allPairs{i}{1}.TimeStamp.mapTs{k}.M2toM1;
        if length(M1toM2) > length(M2toM1)
           filt2 = filt2(M2toM1);
        else
           filt1 = filt1(M1toM2); 
        end
        minilen = min([length(filt1), length(filt2)]);
        cor_value = corr(filt1(1:minilen), filt2(1:minilen));
        this_cor = [this_cor, cor_value];
        fprintf(['Pair %d ', allPairs{i}{1}.videoInfo.session{k}, ' correlation is %4.4f\n'], i, cor_value);
        
    end
    cor_values(PairID) = this_cor;
end
%% find timestamp mapping with different length than the timestamp of the ms
for i = 1:length(allPairs)
        for k = 1:length(allPairs{i}{j}.MS)
            if length(allPairs{i}{1}.TimeStamp.mapTs{k}.M1toM2) ~= size(allPairs{i}{2}.MS{k}.FiltTraces,1)
                fprintf('Pair %d, session %d, M1toM2\n',i,k);
            end
            if length(allPairs{i}{1}.TimeStamp.mapTs{k}.M2toM1) ~= size(allPairs{i}{1}.MS{k}.FiltTraces,1)
                fprintf('Pair %d, session %d, M2toM1\n',i,k);
            end
            
        
        end
end
            
            

