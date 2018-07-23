function plotdiff

load('diff_stats.mat');

stats.pdist = max(stats.wplidiff,[],2);
stats.ndist = min(stats.wplidiff,[],2);

% meandiff = repmat(mean(stats.wplidiff,1),size(stats.wplidiff,1),1);
% stddiff = repmat(std(stats.wplidiff,[],1),size(stats.wplidiff,1),1);

% stats.pstat = (stats.wplidiff - meandiff) ./ (stddiff / sqrt(numrand+1));
% stats.pstat(stats.pstat < 0) = 0;

stats.pstat = stats.wplidiff;
stats.pstat(stats.pstat < 0) = 0;

stats.pprob = ones(1,size(stats.wplidiff,2));
for n = 1
    for p = 1:size(stats.wplidiff,2)
        stats.pprob(n,p) = sum(stats.pdist >= stats.wplidiff(n,p))/size(stats.pdist,1);
    end
end

% stats.nstat = (test_stat - meandiff) ./ (stddiff / sqrt(numrand+1));
% stats.nstat(stats.pstat > 0) = 0;
stats.alpha = 0.05;
stats.N = stats.numchan;
stats.size = 'intensity';
stats.thresh = min(stats.pstat(1,stats.pprob < stats.alpha));
stats.test_stat = stats.pstat;

[~,n_nets,netmask,netpval] = evalc('NBSstats(stats)');

coh = zeros(stats.numchan,stats.numchan);
coh(logical(tril(ones(size(coh)),-1))) = stats.wplidiff(1,:);
coh = tril(coh,1)+tril(coh,1)';
coh(coh < 0) = 0;
plotgraph3d(coh,'escale',[0 1],'vscale',[0 1]);
netmask{1} = full(netmask{1});
netmask{1} = triu(netmask{1},1)+triu(netmask{1},1)';
coh(~netmask{1}) = 0;
plotgraph3d(coh,'escale',[0 1],'vscale',[0 1]);