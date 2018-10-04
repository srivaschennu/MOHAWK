function groupdata(listname,varargin)

param = finputcheck(varargin, {
    'group', 'string', [], 'crsdiag'; ...
    });


loadpaths

loadsubj

subjlist = eval(listname);

loadcovariates
grp = eval(param.group);

savename = sprintf('%s/groupdata_%s.mat',filepath,listname);
filesuffix = '_mohawk';

% load /Users/chennu/Work/EGI/173to91.mat keepidx

for s = 1:size(subjlist,1)
    basename = strtok(subjlist{s,1}{1},'.');
    
    fprintf('Processing %s.\n',basename);
    loadname = sprintf('%s/%s%s%s.mat',filepath,basename,filesuffix);
    load(loadname);
    load(loadname,'freqs');
    
    if s == 1
        freqbins = freqs;
        allspec = zeros(size(subjlist,1),length(chanlocs),length(freqs));
        bandpower = zeros(size(subjlist,1),size(matrix,1),length(chanlocs));
        allcoh = zeros(size(subjlist,1),size(matrix,1),length(chanlocs),length(chanlocs));
        graph = graphdata(:,1);
        for m = 1:size(graph,1)
            graph{m,2} = zeros([size(subjlist,1) size(graphdata{m,2})]);
        end
%         allwsmi = zeros(size(subjlist,1),size(matrix,1),length(chanlocs),length(chanlocs));
    end
    
    if size(matrix,2) == 173
        matrix = matrix(:,keepidx,keepidx);
        spectra = spectra(keepidx,:);
        bpower = bpower(:,keepidx);
        for m = 1:size(graph,1)
            if ndims(graphdata{m,2}) == 3
                graphdata{m,2} = graphdata{m,2}(:,:,keepidx);
            end
        end
    end
    
    matrix(isnan(matrix)) = 0;
    matrix = abs(matrix);
    allcoh(s,:,:,:) = matrix;
%     allwsmi(s,:,:,:) = wsmi;
    allspec(s,:,:) = spectra;
    bandpower(s,:,:) = bpower;
    for m = 1:size(graph,1)
        graph{m,2}(s,:) = graphdata{m,2}(:);
    end
end

save(savename, 'grp', 'allspec', 'freqbins', 'bandpower', ...
    'allcoh', 'subjlist', 'graph', 'tvals', 'subjlist');