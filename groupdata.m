function groupdata(listname)

loadpaths

loadsubj

subjlist = eval(listname);

loadcovariates
grp = crsdiag;

savename = sprintf('%s/groupdata_%s.mat',filepath,listname);
filesuffix = '_mohawk';

for s = 1:size(subjlist,1)
    basename = strtok(subjlist{s,1},'.');
    
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
    end
    
    matrix(isnan(matrix)) = 0;
    matrix = abs(matrix);
    allcoh(s,:,:,:) = matrix;
    allspec(s,:,:) = spectra;
    bandpower(s,:,:) = bpower;
    for m = 1:size(graph,1)
        graph{m,2}(s,:) = graphdata{m,2}(:);
    end
end

save(savename, 'grp', 'allspec', 'freqbins', 'bandpower', 'allcoh', 'subjlist', 'graph', 'tvals', 'subjlist');