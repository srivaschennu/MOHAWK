covariatenames = subjlist(1,:);
subjlist = subjlist(2:end,:);

for c = 2:length(covariatenames)
    eval(sprintf('%s = cell2mat(subjlist(:,c));',covariatenames{c}));
end

subjlist = cell2table(subjlist,'VariableNames',covariatenames);