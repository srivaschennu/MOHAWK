covariatenames = subjlist(1,:);
subjlist = subjlist(2:end,:);

for c = 1:length(covariatenames)
    eval(sprintf('%s = cell2mat(subjlist(:,c));',covariatenames{c}));
end