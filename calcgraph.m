function calcgraph(basename,varargin)

loadpaths

param = finputcheck(varargin, {
    'heuristic', 'integer', [], 50; ...
    });

tvals = 1:-0.025:0.1;

savename = sprintf('%s/%s_mohawk.mat',filepath,basename);
load(savename,'matrix','chanlocs');

load(sprintf('sortedlocs_%d.mat',length(chanlocs)),'chandist');
chandist = chandist / max(chandist(:));

graphdata{1,1} = 'clustering';
graphdata{2,1} = 'characteristic path length';
graphdata{3,1} = 'global efficiency';
graphdata{4,1} = 'modularity';
graphdata{5,1} = 'modules';
graphdata{6,1} = 'centrality';
graphdata{7,1} = 'modular span';
graphdata{8,1} = 'participation coefficient';
graphdata{9,1} = 'degree';
graphdata{10,1} = 'mutual information';

fprintf('Processing data set %s\n',basename);

for f = 1:size(matrix,1)
    fprintf('Frequency band %d\n',f);
    cohmat = squeeze(matrix(f,:,:));
    cohmat(isnan(cohmat)) = 0;
    cohmat = abs(cohmat);
    
    for thresh = 1:length(tvals)
        bincoh = double(threshold_proportional(cohmat,tvals(thresh)) ~= 0);
        
        allcc(thresh,:) = clustering_coef_bu(bincoh);
        allcp(thresh) = charpath(distance_bin(bincoh),0,0);
        alleff(thresh) = efficiency_bin(bincoh);
        allbet(thresh,:) = betweenness_bin(bincoh);
        alldeg(thresh,:) = degrees_und(bincoh);
        
        for i = 1:param.heuristic
            [Ci, allQ(thresh,i)] = community_louvain(bincoh);
            
            allCi(thresh,i,:) = Ci;
            
            modspan = zeros(1,max(Ci));
            for m = 1:max(Ci)
                if sum(Ci == m) > 1
                    distmat = chandist(Ci == m,Ci == m) .* bincoh(Ci == m,Ci == m);
                    distmat = nonzeros(triu(distmat,1));
                    modspan(m) = sum(distmat)/sum(Ci == m);
                end
            end
            allms(thresh,i) = max(nonzeros(modspan));
            allpc(thresh,i,:) = participation_coef(bincoh,Ci);
        end
    
        %clustering coeffcient
        graphdata{1,2}(f,thresh,1:length(chanlocs)) = allcc(thresh,:);
        
        %characteristic path length
        graphdata{2,2}(f,thresh) = allcp(thresh);
        
        %global efficiency
        graphdata{3,2}(f,thresh) = alleff(thresh);
        
        % modularity
        graphdata{4,2}(f,thresh) = mean(allQ(thresh,:));
        
        % community structure
        graphdata{5,2}(f,thresh,1:length(chanlocs)) = squeeze(allCi(thresh,1,:));
        
        %betweenness centrality
        graphdata{6,2}(f,thresh,1:length(chanlocs)) = allbet(thresh,:);
        
        %modular span
        graphdata{7,2}(f,thresh) = mean(allms(thresh,:));
        
        %participation coefficient
        graphdata{8,2}(f,thresh,1:length(chanlocs)) = mean(squeeze(allpc(thresh,:,:)));
        
        %degree
        graphdata{9,2}(f,thresh,1:length(chanlocs)) = alldeg(thresh,:);
    end
end
fprintf('\n');

save(savename, 'graphdata', 'tvals', '-append');