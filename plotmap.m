function plotmap(listname,measure,bandidx,varargin)

param = finputcheck(varargin, {
    'group', 'string', [], 'crsdiag'; ...
    'groupnames', 'cell', {}, {'UWS','MCS-','MCS+','EMCS','LIS','CTR'}; ...
    'pmask', 'string', [], ''; ...
    'clim', 'real', [], [-0.5 0.5]; ...
    'legend', 'string', {'on','off'}, 'off'; ...
    'legendlocation', 'string', [], 'Best'; ...
    'noplot', 'string', {'on','off'}, 'off'; ...
    'plotcm', 'string', {'on','off'}, 'off'; ...
    });

fontname = 'Helvetica';
fontsize = 22;

loadpaths

load(sprintf('%s/groupdata_%s.mat',filepath,listname));
groupvar = grp;

changroups

load(sprintf('sortedlocs_%d.mat',length(chanlocs)));

bands = {
    'delta'
    'theta'
    'alpha'
    'beta'
    'gamma'
    };

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

groupnames = param.groupnames;
weiorbin = 2;

if ~isempty(param.pmask)
    pmaskidx = ismember({sortedlocs.labels},cat(1,eval(param.pmask)));
end

if strcmpi(measure,'power')
    
    testdata = squeeze(bandpower(:,bandidx,:)) * 100;
else
    plotqt = 0.3;
    plotqt = find(abs(tvals - plotqt) == min(abs(tvals - plotqt)),1,'first');
    
    trange = [0.9 0.1];
    trange = (tvals <= trange(1) & tvals >= trange(2));
    
    m = find(strcmpi(measure,graph(:,1)));
    if strcmpi(measure,'centrality')
        testdata = squeeze(max(graph{m,weiorbin}(:,bandidx,plotqt,:),[],4));
    elseif strcmpi(measure,'participation coefficient')
        testdata = zscore(graph{m,weiorbin}(:,bandidx,trange,:),0,4);
        testdata = squeeze(mean(testdata,3));
    end
end

bands = {
    'delta'
    'theta'
    'alpha'
    'beta'
    'gamma'
    };

groups = unique(groupvar(~isnan(groupvar)));

for g = 1:length(groups)
    groupmap = squeeze(mean(testdata(groupvar == groups(g),:),1));
    figure;
    figpos = get(gcf,'Position');
    figpos(3) = figpos(3)/2;
    set(gcf,'Position',figpos);
    if ~isempty(param.pmask)
         topoplot(groupmap,sortedlocs,'maplimits',param.clim,'gridscale',150,...
        'pmask',pmaskidx);
    else
        topoplot(groupmap,sortedlocs,'maplimits',param.clim,'gridscale',150,...
            'style','map');
    end
    colormap(jet);
    %colorbar
    figname = sprintf('%s/figures/map_%s_%s_%s',filepath,measure,groupnames{g},bands{bandidx});
    set(gcf,'Name',figname,'Color','white');
    set(gca,'FontName',fontname,'FontSize',fontsize);
    print(gcf,[figname '.tif'],'-r150','-dtiff');
    close(gcf);
end