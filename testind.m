function testind(basename)

loadpaths
changroups

clsyfyrlist = {
    'svm-rbf_UWS_MCS-'
%     'tree_UWS_MCS-'
% %     'nn_UWS_MCS-'
%     'knn_UWS_MCS-'
%     'nbayes_UWS_MCS-'
    };

weiorbin = 2;

savefile = sprintf('%s/%s_mohawk.mat',filepath,basename);
load(savefile,'bpower','matrix','graphdata','tvals');

fprintf('Loading classifiers:');
for c = 1:length(clsyfyrlist)
    fprintf(' %s',clsyfyrlist{c});
    if c == 1
        load(sprintf('%s/%s.mat',filepath,clsyfyrlist{c}),'output1','output2','clsyfyrinfo');
        clsyfyr = vertcat(output1{:});
        model = output2;
    elseif c > 1
        nextclsyfyr = load(sprintf('%s/%s.mat',filepath,clsyfyrlist{c}),'output1','output2','clsyfyrinfo');
        clsyfyr = cat(1,clsyfyr,vertcat(nextclsyfyr.output1{:}));
        model = cat(1,model,nextclsyfyr.output2);
        clsyfyrinfo.clsyfyrparam = cat(1,clsyfyrinfo.clsyfyrparam,nextclsyfyr.clsyfyrinfo.clsyfyrparam);
    end
end
fprintf('\n');

clear output1 output2

fprintf('Testing with clsyfyr');
for k = 1:size(clsyfyrinfo.clsyfyrparam,1)
    if k > 1
        fprintf(repmat('\b',1,length(progstr)));
    end
    progstr = sprintf(' %d/%d',k,size(clsyfyrinfo.clsyfyrparam,1));
    fprintf(progstr);
    
    measure = clsyfyrinfo.clsyfyrparam{k,1};
    bandidx = find(strcmp(clsyfyrinfo.clsyfyrparam{k,2},clsyfyrinfo.bands));
    
    if strcmpi(measure,'power')
        features = bpower(bandidx,:) * 100;
    elseif strcmpi(measure,'median')
        features = median(matrix(bandidx,:,:),3);
    elseif strcmpi(measure,'mean')
        features = mean(matrix(bandidx,:,:),3);
    else
        m = strcmpi(measure,graphdata(:,1));
        features = graphdata{m,weiorbin}(bandidx,:,:);
        
        %round down to 3 decimal places
        precision = 3;
        threshidx = ismember(round(tvals * 10^precision),round(clsyfyrinfo.clsyfyrparam{k,3} * 10^precision));
        if ~all(round(tvals(threshidx) * 10^precision) == round(clsyfyrinfo.clsyfyrparam{k,3} * 10^precision))
            error('getfeatures: some requested thresholds not found!');
        end
        features = features(:,threshidx,:);
    end
    
    if ndims(features) == 3
        features = permute(features,[1 3 2]);
    end
    
    if ~isempty(clsyfyr(k).pcaCoeff)
        features = features * clsyfyr(k).pcaCoeff;
    end
    
    switch clsyfyrinfo.clsyfyrparam{k,4}{1}
        case {'knn' 'svm-linear' 'svm-rbf' 'tree' 'nbayes'}
            testres{k,1}.predlabels = predict(model{k}, features);
            
        case 'nn'
            testres{k,1}.predlabels = (vec2ind(compet(model{k}(features')))-1)';
    end    
end
fprintf('\n');

save(savefile,'clsyfyrinfo','testres','-append');