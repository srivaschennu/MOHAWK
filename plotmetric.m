function plotmetric(basename,measure,bandidx,varargin)

listname = 'allsubj';

loadpaths

param = finputcheck(varargin, {
    'ylim', 'real', [], []; ...
    'legend', 'string', {'on','off'}, 'on'; ...
    'plotinfo', 'string', {'on','off'}, 'on'; ...
    'plotticks', 'string', {'on','off'}, 'on'; ...
    'ylabel', 'string', {}, measure; ...
    'randratio', 'string', {'on','off'}, 'off'; ...
    'legendposition', 'string', {}, 'NorthEast'; ...
    });

fontname = 'Helvetica';
fontsize = 20;

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

load(sprintf('%s/%s_mohawk.mat',filepath,basename));
load(sprintf('%s/groupdata_%s.mat',filepath,listname));

weiorbin = 2;

groups = [0 1 2 3 4 5 6];
groupnames = {
    'UWS'
    'MCS-'
    'MCS+'
    'EMCS'
    'LIS'
    'CTRL'
    };

bands = {
    'Delta'
    'Theta'
    'Alpha'
    'Beta'
    'Gamma'
    };

trange = [0.9 0.1];
trange = (tvals <= trange(1) & tvals >= trange(2));

m = find(strcmpi(measure,graph(:,1)));

barvals = zeros(3,length(groups));
errvals = zeros(3,length(groups));

selpatidx = ismember(grp,groups);

if strcmp(measure,'modules')
    groupvals = squeeze(mean(max(graph{m,weiorbin}(selpatidx,bandidx,trange,:),[],4),3));
    patvals = squeeze(mean(max(graphdata{m,weiorbin}(bandidx,:,:),[],3),2));
elseif strcmp(measure,'mutual information')
    groupvals = squeeze(mean(mean(graph{m,weiorbin}(selpatidx,grp == groups(g),bandidx,trange),4),2));
    patvals = squeeze(mean(mean(graphdata{m,weiorbin}(grp == groups(g),bandidx,trange),4),2));
elseif strcmp(measure,'participation coefficient')
    groupvals = squeeze(mean(std(graph{m,weiorbin}(selpatidx,bandidx,trange,:),[],4),3));
    patvals = squeeze(mean(std(graphdata{m,weiorbin}(bandidx,trange,:),[],3),2));
elseif strcmp(measure,'median')
    groupvals = nanmedian(allcoh(selpatidx,bandidx,:),3);
    patvals = nanmedian(matrix(bandidx,:),2);
else
    groupvals = squeeze(mean(mean(graph{m,weiorbin}(selpatidx,bandidx,trange,:),4),3));
    patvals = squeeze(mean(mean(graphdata{m,weiorbin}(bandidx,trange,:),3),2));
end

plotvals = cat(1,groupvals,patvals);
groupnames = cat(1,groupnames,{'PAT'});

figure('Color','white','Name',basename)
plotgroups = [grp(selpatidx); max(grp(selpatidx))+1];
[plotgroups,~,uniqgroups] = unique(plotgroups);
boxh = notBoxPlot(plotvals,uniqgroups,0.5,'patch',ones(length(plotvals),1));
for h = 1:length(boxh)
    set(boxh(h).data,'Color',colorlist(h,:),'MarkerFaceColor',facecolorlist(h,:))
end
set(gca,'XLim',[0.5 length(plotgroups)+0.5],'XTick',1:length(plotgroups),...
    'XTickLabel',groupnames,'FontName',fontname,'FontSize',fontsize);

if strcmp(param.plotticks,'on')
    set(gca,'FontName',fontname,'FontSize',fontsize);
    ylabel(param.ylabel,'FontName',fontname,'FontSize',fontsize);
end

if ~isempty(param.ylim)
    ylim(param.ylim);
end

print(gcf,sprintf('%s/figures/%s_%s_%s.tif',filepath,basename,measure,bands{bandidx}),'-dtiff','-r150');
close(gcf);