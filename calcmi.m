function calcmi(listname,varargin)

loadpaths

measure = 'modules';

param = finputcheck(varargin, {
    'randratio', 'string', {'on','off'}, 'off'; ...
    });

load(sprintf('%s/groupdata_%s.mat',filepath,listname),'graph','tvals','subjlist');
% ctrlgraph = load(sprintf('%s/groupdata_ctrllist.mat',filepath),'graph','tvals');

weiorbin = 2;

if any(strcmp('mutual information',graph(:,1)))
    midx = find(strcmp('mutual information',graph(:,1)));
else
    graph{end+1,1} = 'mutual information';
    midx = size(graph,1);
end

modinfo = graph{strcmp(measure,graph(:,1)),weiorbin};

% allctrl = ctrlgraph.graph{strcmp(measure,graph(:,1)),weiorbin};
% meanctrl = squeeze(mean(ctrlgraph.graph{strcmp(measure,graph(:,1)),weiorbin}(crsdiag == 5,:,:,:),1));

mutinfo = nan(size(modinfo,1),size(modinfo,1),size(modinfo,2),size(modinfo,3));

for bandidx = 1:size(modinfo,2)
    fprintf('band %d, threshold', bandidx);
    for t = 1:size(modinfo,3)
        fprintf(' %d',t);
        for s1 = 1:size(modinfo,1)
            for s2 = 1:size(modinfo,1)
                if s1 < s2
                    %                 mutinfo(s1,s2,bandidx,t) = ...
                    %                     corr(squeeze(modinfo(s1,bandidx,t,:)),squeeze(allctrl(s2,bandidx,t,:)));
                    [~, mutinfo(s1,s2,bandidx,t)] = ...
                        partition_distance(squeeze(modinfo(s1,bandidx,t,:)),squeeze(modinfo(s2,bandidx,t,:)));
                elseif s1 > s2
                    mutinfo(s1,s2,bandidx,t) = mutinfo(s2,s1,bandidx,t);
                end
            end
        end
    end
    fprintf('\n');
end

graph{midx,weiorbin} = mutinfo;
fprintf('Appending mutual information to %s/groupdata_%s.mat.\n',filepath,listname);
save(sprintf('%s/groupdata_%s.mat',filepath,listname), 'graph','-append');
