function preplocs(allchanlocs)

[~,sortidx] = sort({allchanlocs.labels});
sortedlocs = allchanlocs(sortidx);
chanlist = cell2mat({sortedlocs.labels});

splinefile = 'allchanlocs.spl';
chanlocsfile = 'sortedlocs.mat';
headplot('setup',allchanlocs,splinefile);
chandist = ichandist(sortedlocs,'type','euclidean');
save(chanlocsfile, "chanlist", "sortedlocs", "allchanlocs", "chandist")