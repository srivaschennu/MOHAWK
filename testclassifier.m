function testclassifier(listname,trainfile,savesuffix,varargin)

param = finputcheck(varargin, {
    'group', 'string', [], 'crsdiagwithcmd'; ...
    'groups', 'integer', [], [0 1 2 3]; ...
    'groupnames', 'cell', {}, {'UWS','MCS-','MCS+','EMCS'}; ...
    'downsample', 'string', {'true','false'}, 'false'; ...
    });

loadpaths
loadsubj

subjlist = eval(listname);

loadcovariates

% load 173to91.mat

groupvar = eval(param.group);

selgroupidx = ismember(groupvar,param.groups);
groupvar = groupvar(selgroupidx);
[~,~,groupvar] = unique(groupvar);
groupvar = groupvar-1;

load(sprintf('%sclsyfyr_%s_%s.mat',filepath,param.group,trainfile));
clsyfyr = vertcat(output1{:});
model = output2;
clear output1 output2

clsyfyrinfo.trange = 0.9:-0.1:0.1;

clsyfyrinfo.bands = {
    'delta'
    'theta'
    'alpha'
    };

fprintf('Testing with clsyfyr');
for k = 1:size(clsyfyrinfo.clsyfyrparam,1)
    if k > 1
        fprintf(repmat('\b',1,length(progstr)));
    end
    progstr = sprintf(' %d/%d',k,size(clsyfyrinfo.clsyfyrparam,1));
    fprintf(progstr);
    
    output1{k,1}.truelabels = groupvar;
    
    measure = clsyfyrinfo.clsyfyrparam{k,1};
    bandidx = find(strcmp(clsyfyrinfo.clsyfyrparam{k,2},clsyfyrinfo.bands));
    
    features = getfeatures(listname,measure,bandidx,'trange',clsyfyrinfo.clsyfyrparam{k,3});
    features = features(selgroupidx,:,:);
    
    features = permute(features,[1 3 2]);
    
    if strcmp(param.downsample,'true') && size(features,2) > 1
        features = features(:,keepidx,:);
    end
    
    if ~isempty(clsyfyr(k).pcaCoeff)
        features = features * clsyfyr(k).pcaCoeff;
    end
    
    switch clsyfyrinfo.clsyfyrparam{k,4}{1}
        case {'knn' 'svm-linear' 'svm-rbf' 'tree' 'nbayes'}
            output1{k}.predlabels = predict(model{k}, features);
            
        case 'nn'
            output1{k}.predlabels = (vec2ind(compet(model{k}(features')))-1)';
    end
    
    cm = confusionmat(output1{k}.truelabels,output1{k}.predlabels);
    output1{k}.testcm = cm;
    output1{k}.testperf = mean( diag( cm ./ repmat(sum(cm,2),1,size(cm,2)) ) );
end
fprintf('\n');

savefile = sprintf('%sclsyfyr_%s_%s_%s_test.mat',filepath,param.group,listname,savesuffix);
save(savefile,'clsyfyrinfo','output1');