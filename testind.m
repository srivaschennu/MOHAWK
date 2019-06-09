function testind(basename,varargin)

% Copyright (C) 2018 Srivas Chennu, University of Kent and University of Cambrige,
% srivas@gmail.com
% 
% 
% Tests this individual's data against a previously estimated
% classification ensemble to generate a prediction.
% 
%
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
% 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <https://www.gnu.org/licenses/>.

param = finputcheck(varargin, {
    'nclsyfyrs', 'real', [], 50; ...
    });

loadpaths
changroups

clsyfyrlist = {
    'svm-rbf_UWS_MCS-'
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
            testres(k).predlabels = predict(model{k}, features);
            
        case 'nn'
            testres(k).predlabels = (vec2ind(compet(model{k}(features')))-1)';
    end    
end
fprintf('\n');

for c = 1:length(clsyfyr)
    clsyfyr(c).cm = round(clsyfyr(c).cm * 100 ./ repmat(sum(clsyfyr(c).cm,2),1,size(clsyfyr(c).cm,2),1));
    clsyfyr(c).cm = clsyfyr(c).cm + eps;
    clsyfyr(c).cm = clsyfyr(c).cm ./ repmat(sum(clsyfyr(c).cm,1),size(clsyfyr(c).cm,1),1,1);
end

fprintf('Combining classifiers.\n');
listname = 'liege';
load(sprintf('%s/combclsyfyr_%s.mat',filepath,listname),'perfsort','perfsort');

for k = 1:length(perfsort)
    thispred = testres(perfsort(k)).predlabels;
    indprob(k,:) = clsyfyr(perfsort(k)).cm(:,thispred+1);
    if k == 1
        combprob(k,:) = indprob(k,:);
    else
        combprob(k,:) = combprob(k-1,:) .* indprob(k,:);
    end
    combprob(k,:) = combprob(k,:) ./ sum(combprob(k,:));
end

save(savefile,'clsyfyrinfo','testres','indprob','combprob','-append');