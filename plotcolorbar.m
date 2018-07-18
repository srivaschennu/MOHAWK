function plotcolorbar(clim)

loadpaths

figure('Color','black','Name','colorbar');
set(gca,'Visible','off','FontSize',50);
caxis(clim);

% cmap = jet;
% cmap = cmap(size(cmap,1)/2:end,:);

cmap = lines;
cmap = cmap([1:4],:);

colormap(cmap);

cb_h = colorbar('Location','West');
figname = get(gcf,'Name');

set(gcf,'Color','black');
set(cb_h,'YColor',[1 1 1])
set(cb_h,'YTick',[0 1],'YTickLabel',{'Low','High'})

set(cb_h,'YTick',[]);

export_fig(gcf,sprintf('%sfigures/%s.tif',filepath,figname),'-r300');
close(gcf);