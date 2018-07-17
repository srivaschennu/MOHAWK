function clsyfyrorder = combmulticlassifier(clsyfyrlist,varargin)

param = finputcheck(varargin, {
    'mode', 'string', {'eval','test'}, 'eval'; ...
    'testlist', 'cell', {}, {}; ...
    'group', 'string', [], 'crsdiagwithcmd'; ...
    'nclsyfyrs', 'real', [], []; ...
    'outofclass', 'string', {'true','false'}, 'false'; ...
    });

loadpaths
loadsubj

colorlist = [
    0 0.0 0.5
    0 0.5 0
    0.5 0.0 0
    0   0.5 0.5
    0.5 0   0.5
    0.5 0.5 0
    ];

facecolorlist = [
    0.75  0.75 1
    0.25 1 0.25
    1 0.75 0.75
    0.75 1 1
    1 0.75 1
    1 1 0.5
    ];

fontsize = 20;

fprintf('Loading classifiers:');
for c = 1:length(clsyfyrlist)
    fprintf(' %s',clsyfyrlist{c});
    if strcmp(param.mode,'test')
        fprintf(' %s',param.testlist{c});
    end
    
    if c == 1
        load(sprintf('%sclsyfyr_%s_%s.mat',filepath,param.group,clsyfyrlist{c}),'output1','clsyfyrinfo');
        clsyfyr = vertcat(output1{:});
        if strcmp(param.mode,'test')
            load(sprintf('%sclsyfyr_%s_%s.mat',filepath,param.group,param.testlist{c}),'output1');
            testres = vertcat(output1{:});
        end
    elseif c > 1
        nextclsyfyr = load(sprintf('%sclsyfyr_%s_%s.mat',filepath,param.group,clsyfyrlist{c}),'output1','clsyfyrinfo');
        clsyfyr = cat(1,clsyfyr,vertcat(nextclsyfyr.output1{:}));
        clsyfyrinfo.clsyfyrparam = cat(1,clsyfyrinfo.clsyfyrparam,nextclsyfyr.clsyfyrinfo.clsyfyrparam);
        if strcmp(param.mode,'test')
            nextclsyfyr = load(sprintf('%sclsyfyr_%s_%s.mat',filepath,param.group,param.testlist{c}),'output1');
            testres = cat(1,testres,vertcat(nextclsyfyr.output1{:}));
        end
    end
end
fprintf('\n');

if isempty(param.nclsyfyrs)
    param.nclsyfyrs = length(clsyfyr);
end

numgroups = length(clsyfyrinfo.groups);
if strcmp(param.mode,'eval')
    truelabels = clsyfyr(1).truelabels;
    numfolds = clsyfyr(1).numfolds;
    numcvfolds = clsyfyr(1).numcvfolds;
    numruns = numfolds/numcvfolds;
    groupnames = clsyfyrinfo.groupnames;
elseif strcmp(param.mode,'test')
    truelabels = testres(1).truelabels;
    numruns = 1;
    numcvfolds = 1;
    groupnames = clsyfyrinfo.groupnames;
end

if strcmp(param.outofclass,'true')
    truelabels(:) = 1;
end

for c = 1:length(clsyfyr)
    clsyfyr(c).cm = round(clsyfyr(c).cm * 100 ./ repmat(sum(clsyfyr(c).cm,2),1,size(clsyfyr(c).cm,2),1));
    clsyfyr(c).cm = clsyfyr(c).cm + eps;
    clsyfyr(c).cm = clsyfyr(c).cm ./ repmat(sum(clsyfyr(c).cm,1),size(clsyfyr(c).cm,1),1,1);
end

combperf = NaN(param.nclsyfyrs,numruns);
testperf = NaN(param.nclsyfyrs,numruns);
combclassperf = NaN(param.nclsyfyrs,numgroups,numruns);
confmat = NaN(numgroups,numgroups,param.nclsyfyrs,numruns);

[trainperf,perfsort] = sort(arrayfun(@(x) mean(x.perf),clsyfyr),'descend');
trainperf = trainperf(1:param.nclsyfyrs);
clsyfyrorder = clsyfyrinfo.clsyfyrparam(perfsort,:);

fprintf('CV run');
for c = 1:numruns
    fprintf(' %d',c);
    bel = ones(length(truelabels),numgroups);
    for k = 1:param.nclsyfyrs
        if strcmp(param.mode,'eval')
            testperf(k,c) = clsyfyr(perfsort(k)).testperf(c);
        end
        for f = (c-1)*numcvfolds+1:c*numcvfolds
            if strcmp(param.mode,'eval')
                if sum(~isnan(clsyfyr(perfsort(k)).predlabels(:,f)) ~= ~isnan(clsyfyr(1).predlabels(:,f))) ~= 0
                    error('holdout mismatch');
                end
                thisfold = find(~isnan(clsyfyr(perfsort(k)).predlabels(:,f)));
                thispred = clsyfyr(perfsort(k)).predlabels(thisfold,f);
            elseif strcmp(param.mode,'test')
                thisfold = find(~isnan(testres(perfsort(k)).predlabels(:,f)));
                thispred = testres(perfsort(k)).predlabels(:,f);
                if k == 1
                    bel = ones(length(truelabels),numgroups);
                end
            end
            
            for p = 1:size(thisfold,1)
                bel(thisfold(p),:) = bel(thisfold(p),:) .* clsyfyr(perfsort(k)).cm(:,thispred(p)+1,f)';
                if p == 8
                    savedata(k,:) = clsyfyr(perfsort(k)).cm(:,thispred(p)+1,f)';
                end
            end
        end
        bel = bel ./ repmat(sum(bel,2),1,size(bel,2));
        predlabels = round(sum(bel .* repmat(1:size(bel,2),size(bel,1),1),2));
        predlabels = predlabels - 1;
        
        if strcmp(param.outofclass,'true')
            predlabels(predlabels ~= 0) = 1;
        end
        
        cm = confusionmat(truelabels,predlabels);
        confmat(:,:,k,c) = cm;
        
        normcm = cm ./ repmat(sum(cm,2),1,size(cm,2));
        combperf(k,c) = mean(diag(normcm));
        combclassperf(k,:,c) = diag(normcm);
    end
end

fprintf('\nDone.\n');
fig_h = figure('Color','white','Name',cell2mat(clsyfyrlist));
% fig_h.Position(3) = fig_h.Position(3) * 1.5;
hold all

combperf = combperf * 100; testperf = testperf * 100; trainperf = trainperf * 100; combclassperf = combclassperf * 100;

combperf = mean(combperf,2);
testperf = mean(testperf,2);

plot(combperf,'LineWidth',2,'Color','black','DisplayName','Combined');
for g = 1:numgroups
    plot(mean(combclassperf(:,g,:),3),'LineWidth',0.5,'LineStyle','-.','Color',colorlist(g,:),'DisplayName',groupnames{g});
end
plot(trainperf,'LineStyle','--','LineWidth',0.5,'Color',colorlist(g+1,:),'DisplayName','Train');
plot(testperf,'LineStyle','--','LineWidth',0.5,'Color',colorlist(g+2,:),'DisplayName','Test');

plot([1 param.nclsyfyrs],[100/numgroups 100/numgroups],'Color','blue',...
    'LineStyle',':','LineWidth',1.5,'DisplayName','Chance');

legend('Location','SouthEast');

[~,bestk] = max(combperf);
legendoff(plot([1 bestk],[combperf(bestk) combperf(bestk)],'LineStyle',':','LineWidth',1.5,'Color','black'));
[~,besttest] = max(testperf);
legendoff(plot([1 besttest],[testperf(besttest) testperf(besttest)],'LineStyle',':','LineWidth',1.5,'Color','black'));

xlim([1 param.nclsyfyrs]);

set(gca,'FontName','Helvetica','FontSize',fontsize);
xlabel('Number of classifiers','FontName','Helvetica','FontSize',fontsize);
ylabel('Accuracy','FontName','Helvetica','FontSize',fontsize);

[~,bestk] = max(combperf);
plot([bestk bestk],ylim,...
    'LineStyle','-','LineWidth',1.5,'Color','red','DisplayName','Peak accuracy');
print(gcf,sprintf('%s/figures/combclsyfyr_perf.tif',filepath),'-dtiff','-r150');
close(gcf);

plotconfusionmat(sum(confmat(:,:,bestk,:),4),groupnames);
print(gcf,sprintf('%s/figures/combclsyfyr_cm.tif',filepath),'-dtiff','-r150');
close(gcf);