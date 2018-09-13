function plotmi(listname,bandidx,varargin)

loadpaths


param = finputcheck(varargin, {
    'caxis', 'real', [], []; ...
    'renderer', 'string', {'painters','opengl'}, 'painters'; ...
    'colorbar', 'string', {'on','off'}, 'on'; ...
    });

fontname = 'Helvetica';
fontsize = 28;

load(sprintf('%s/groupdata_%s.mat',filepath,listname),'graph','subjlist','tvals');
grp = subjlist.('crsdiag');

weiorbin = 2;
trange = [0.5 0.1];
trange = (tvals <= trange(1) & tvals >= trange(2));

bands = {
    'Delta'
    'Theta'
    'Alpha'
    'Beta'
    'Gamma'
    };

groups = unique(grp);
mutinfo = graph{strcmpi('mutual information',graph(:,1)),weiorbin};

figure('Color','white'); hold all
plotdata = mean(mutinfo(:,:,bandidx,trange),4);
[grp,sortidx] = sort(grp);
plotdata = plotdata(sortidx,sortidx);
imagesc(plotdata);
colormap(jet);
axis square

if ~isempty(param.caxis)
    caxis(param.caxis);
end

for g = 1:length(groups)-1
    groupedge(g) = find(grp == groups(g),1,'last');
    line([groupedge(g)+0.5 groupedge(g)+0.5],ylim,'Color','black','LineWidth',4);
    line(xlim,[groupedge(g)+0.5 groupedge(g)+0.5],'Color','black','LineWidth',4);
end
groupedge = [0 groupedge size(plotdata,1)];
for g = 1:length(groupedge)-1
%     line([groupedge(g)+0.5 groupedge(g)+0.5],[groupedge(g)+0.5 groupedge(g+1)+0.5],'Color','red','LineWidth',4);
%     line([groupedge(g)+0.5 groupedge(g+1)+0.5],[groupedge(g+1)+0.5 groupedge(g+1)+0.5],'Color','red','LineWidth',4);
    line([groupedge(g+1)+0.5 groupedge(g+1)+0.5],[groupedge(g)+0.5 groupedge(g+1)+0.5],'Color','red','LineWidth',4);
    line([groupedge(g)+0.5 groupedge(g+1)+0.5],[groupedge(g)+0.5 groupedge(g)+0.5],'Color','red','LineWidth',4);
    line([groupedge(g)+0.5 groupedge(g+1)+0.5],[groupedge(g)+0.5 groupedge(g+1)+0.5],'Color','red','LineWidth',4);
    
    if bandidx == 3 && g < 6
        line([groupedge(g)+0.5 groupedge(g+1)+0.5],[groupedge(end)+0.5 groupedge(end)+0.5],'Color','magenta','LineWidth',4);
        line([groupedge(g)+0.5 groupedge(g+1)+0.5],[groupedge(end-1)+0.5 groupedge(end-1)+0.5],'Color','magenta','LineWidth',4);
        line([groupedge(g)+0.5 groupedge(g)+0.5],[groupedge(end-1)+0.5 groupedge(end)+0.5],'Color','magenta','LineWidth',4);
        line([groupedge(g+1)+0.5 groupedge(g+1)+0.5],[groupedge(end-1)+0.5 groupedge(end)+0.5],'Color','magenta','LineWidth',4);
    end
end

if strcmp(param.colorbar,'on')
    colorbar
end

set(gca,'FontName',fontname,'FontSize',fontsize,'XTick',[],'YTick',[],...
    'XLim',[0.5 size(plotdata,1)+0.5],'YLim',[0.5 size(plotdata,2)+0.5],'YDir','reverse');

export_fig(gcf,sprintf('%s/figures/NMImap_%s.tiff',filepath,bands{bandidx}),sprintf('-%s',param.renderer));

close(gcf);