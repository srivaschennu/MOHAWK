covariatenames = subjlist(1,:);
subjlist = subjlist(2:end,:);

for c = 2:length(covariatenames)
    eval(sprintf('%s = cell2mat(subjlist(:,c));',covariatenames{c}));
end

subjlist = cell2table(subjlist,'VariableNames',covariatenames);

if exist('crsdiag','var')
    crsdiagwithcmd = crsdiag;
    crsdiagwithcmd(crsdiag == 0 & (tennis == 1 | petdiag == 1)) = 6;
    subjlist.crsdiagwithcmd = crsdiagwithcmd;
    
    uniqsubj = unique(subjnum);
    nextcrsdiag = nan(size(crsdiag));
    for s = 1:length(uniqsubj)
        subjidx = find(subjnum == uniqsubj(s));
        nextcrsdiag(subjidx(1:end-1)) = crsdiag(subjidx(2:end));% - crsdiag(subjidx(1:end-1));
    end
    subjlist.nextcrsdiag = nextcrsdiag;
end