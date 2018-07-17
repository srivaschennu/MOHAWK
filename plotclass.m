function [combprob,groupnames] = plotclass(basename,varargin)

param = finputcheck(varargin, {
    'nclsyfyrs', 'real', [], 50; ...
    });

loadpaths

colorlist = [
    0 0.0 0.5
    0 0.5 0
    0.5 0.0 0
    0   0.5 0.5
    0.5 0   0.5
    0.5 0.5 0
    0.25 0.25 0.75
    ];

facecolorlist = [
    0.75  0.75 1
    0.25 1 0.25
    1 0.75 0.75
    0.75 1 1
    1 0.75 1
    1 1 0.5
    0.5 0.5 1
    ];

fontsize = 20;

clsyfyrlist = {
    'svm-rbf_UWS_MCS-'
    };

fprintf('Loading classifiers:');
for c = 1:length(clsyfyrlist)
    fprintf(' %s',clsyfyrlist{c});
    if c == 1
        load(sprintf('%s/%s.mat',filepath,clsyfyrlist{c}),'output1','clsyfyrinfo');
        clsyfyr = vertcat(output1{:});
    elseif c > 1
        nextclsyfyr = load(sprintf('%sclsyfyr_%s_%s.mat',filepath,param.group,clsyfyrlist{c}),'output1','clsyfyrinfo');
        clsyfyr = cat(1,clsyfyr,vertcat(nextclsyfyr.output1{:}));
        clsyfyrinfo.clsyfyrparam = cat(1,clsyfyrinfo.clsyfyrparam,nextclsyfyr.clsyfyrinfo.clsyfyrparam);
    end
end
fprintf('\n');

if isempty(param.nclsyfyrs)
    param.nclsyfyrs = length(clsyfyr);
end

numgroups = length(clsyfyrinfo.groups);
groupnames = clsyfyrinfo.groupnames;

subjfile = sprintf('%s/%s_mohawk.mat',filepath,basename);
load(subjfile);
testres = vertcat(testres{:});

for c = 1:length(clsyfyr)
    clsyfyr(c).cm = round(clsyfyr(c).cm * 100 ./ repmat(sum(clsyfyr(c).cm,2),1,size(clsyfyr(c).cm,2),1));
    clsyfyr(c).cm = clsyfyr(c).cm + eps;
    clsyfyr(c).cm = clsyfyr(c).cm ./ repmat(sum(clsyfyr(c).cm,1),size(clsyfyr(c).cm,1),1,1);
end

indprob = NaN(param.nclsyfyrs,numgroups);
combprob = NaN(param.nclsyfyrs,numgroups);

[~,perfsort] = sort(arrayfun(@(x) mean(x.perf),clsyfyr),'descend');

for k = 1:param.nclsyfyrs
    thispred = testres(perfsort(k)).predlabels;
    indprob(k,:) = clsyfyr(perfsort(k)).cm(:,thispred+1);
    if k == 1
        combprob(k,:) = indprob(k,:);
    else
        combprob(k,:) = combprob(k-1,:) .* indprob(k,:);
    end
    combprob(k,:) = combprob(k,:) ./ sum(combprob(k,:));
end

fig_h = figure('Color','white','Name',basename);
% fig_h.Position(3) = fig_h.Position(3) * 1.5;
hold all

for g = 1:numgroups
    plot(combprob(:,g),'LineWidth',2,'Color',colorlist(g,:),...
        'DisplayName',sprintf('p(%s) Combined',groupnames{g}));
end
% for g = 1:numgroups
%     plot(indprob(:,g),'LineWidth',0.5,'LineStyle','-.','Color',colorlist(g,:),...
%         'DisplayName',sprintf('p(%s) Individual',groupnames{g}));
% end

legend('toggle','Location','best');

xlim([1 param.nclsyfyrs]);
ylim([0 1]);

set(gca,'FontName','Helvetica','FontSize',fontsize);
xlabel('Number of classifiers','FontName','Helvetica','FontSize',fontsize);
ylabel('Class probability','FontName','Helvetica','FontSize',fontsize);

print(gcf,sprintf('%s/figures/%s_combprob.tif',filepath,basename),'-dtiff','-r150');
close(gcf);

combprob = mean(combprob,1);

fig_h = figure('Color','white','Name',basename);
fig_h.Position(3) = fig_h.Position(3) * 2/3;
for g = 1:numgroups
    bar(g,combprob(g),'FaceColor',colorlist(g,:),'LineWidth',1.5);
    hold all
end
set(gca,'FontName','Helvetica','FontSize',fontsize);
set(gca,'XTick',1:numgroups,'XTickLabel',groupnames);
ylim([0 1]);
ylabel('Probability');
print(gcf,sprintf('%s/figures/%s_prob.tif',filepath,basename),'-dtiff','-r150');
close(gcf);
