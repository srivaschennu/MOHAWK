function clsyfyr = buildecc(listname,varargin)

param = finputcheck(varargin, {
    'mode', 'string', {'eval','test'}, 'eval'; ...
    'groups', 'real', [], [0 1 2]; ...
    });


group = 'crsdiag';

loadpaths
load(sprintf('%s%s.mat',filepath,listname));
subjlist = eval(listname);

loadcovariates

groupvar = eval(group);
if strcmp(param.mode,'eval')
    groups = param.groups;
elseif strcmp(param.mode,'test')
%     groups = unique(groupvar(~isnan(groupvar)));
    groups = param.groups;
end

selgroupidx = ismember(groupvar,groups);
groupvar = groupvar(selgroupidx);

clsyfyrlist = {
    'UWS_MCS-'  [1  -1  0]
    'MCS-_MCS+' [0  1  -1]
%     'UWS_MCS+'  [1  0 -1]
    };

predlabels = NaN(size(groupvar,1),size(clsyfyrlist,1));

ecccode = NaN(length(param.groups),size(clsyfyrlist,1));
for c = 1:size(clsyfyrlist,1)
    bincls = load(sprintf('clsyfyr_%s_%s.mat',group,clsyfyrlist{c,1}));
    if strcmp(param.mode,'eval')
        predlabels(groupvar == bincls.groups(1) | groupvar == bincls.groups(2),c) = bincls.clsyfyr.predlabels;
    elseif strcmp(param.mode,'test')
        disp(bincls.featlist(1,:));
        features = getfeatures(listname,bincls.featlist{2:3});
        features = features(selgroupidx,:,:);
        rng('default');
        [~,postProb] = predict(fitSVMPosterior(bincls.clsyfyr.model),squeeze(features(:,bincls.clsyfyr.D,:)));
        predlabels(:,c) = double(postProb(:,2) >= bincls.clsyfyr.bestthresh);
    end
    ecccode(:,c) = clsyfyrlist{c,2};
end

predlabels(predlabels == 0) = -1;
predlabels(isnan(predlabels)) = 0;
ecclabels = NaN(size(groupvar));

%ECC algorithm for loss-based decoding (Allwein et al., 2000) with a
%negative exponential loss function
for g = 1:size(groupvar,1)
    dist = zeros(size(ecccode,1),1);
    for k = 1:size(ecccode,1)
        for l = 1:size(ecccode,2)
            dist(k) = dist(k) + (abs(ecccode(k,l)) * lossfunc(ecccode(k,l),predlabels(g,l)));
        end
    end
    [~,ecclabels(g)] = min(dist);
end

ecclabels = ecclabels - 1;

if strcmp(param.mode,'eval')
    clear clsyfyr
    clsyfyr.trainlabels = groupvar;
    clsyfyr.predlabels = ecclabels;
    [clsyfyr.confmat,clsyfyr.chi2,clsyfyr.chi2pval] = crosstab(groupvar,ecclabels);
    save('clsyfyr_ecc.mat','clsyfyr','groups');
elseif strcmp(param.mode,'test')
    disp([groupvar ecclabels]);
    fprintf('Accuracy = %.1f%%.\n', sum(ecclabels == (groupvar > 0)) * 100/length(ecclabels));
end

function loss = lossfunc(y,s)
% loss = (1 - sign(y*s))/2;
loss = -exp(-y*s)/2;
