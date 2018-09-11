function [combprob,groupnames] = plotclass(basename,varargin)

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

subjfile = sprintf('%s/%s_mohawk.mat',filepath,basename);
load(subjfile,'indprob','combprob','clsyfyrinfo');

numgroups = length(clsyfyrinfo.groups);
groupnames = clsyfyrinfo.groupnames;


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

xlim([1 size(combprob,1)]);
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

load(sprintf('%s/combclassifier.mat',filepath),'allbel','truelabels');

figure('Color','white');
figpos = get(gcf,'Position');
figpos(3) = figpos(3)*2/3;
set(gcf,'Position',figpos);

plotvals = mean(mean(allbel(:,2,1,:),4),3);
plotvals = cat(1,plotvals, combprob(2));
plotgroups = truelabels+1;
plotgroups = cat(1,plotgroups,max(truelabels)+2);
plotxticklabels = [groupnames {'Patient'}];
numgroups = numgroups+1;
boxh = notBoxPlot(plotvals,plotgroups,0.5,'patch',ones(size(plotgroups)));
for h = 1:length(boxh)
    set(boxh(h).data,'Color',colorlist(h,:),'MarkerFaceColor',facecolorlist(h,:))
end
set(gca,'FontName','Helvetica','FontSize',fontsize);
set(gca,'XLim',[0.5 numgroups+0.5],'XTick',1:numgroups,'YLim', [0 1], ...
        'XTickLabel',plotxticklabels,'FontName','Helvetica','FontSize',fontsize);
ylabel('Probability','FontName','Helvetica','FontSize',fontsize);
print(gcf,sprintf('%s/figures/%s_allprob.tif',filepath,basename),'-dtiff','-r150');
close(gcf);