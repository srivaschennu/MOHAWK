function preplocs(allchanlocs)

numchan = length(allchanlocs);
[~,sortidx] = sort({allchanlocs.labels});
sortedlocs = allchanlocs(sortidx);
chanlist = cell2mat({sortedlocs.labels});

splinefile = sprintf('allchanlocs_%d.spl', numchan);
chanlocsfile = sprintf('sortedlocs_%d.mat', numchan);
headplot('setup',allchanlocs,splinefile);
chandist = ichandist(sortedlocs,'type','euclidean');
save(chanlocsfile, "chanlist", "sortedlocs", "allchanlocs", "chandist")