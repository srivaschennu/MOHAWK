function plothead(basename,bandidx)

loadpaths

load([filepath filesep basename '_mohawk.mat']);

plotqt = 0.7;

bands = {
    'delta'
    'theta'
    'alpha'
    'beta'
    'gamma'
    };

cohmat = squeeze(matrix(bandidx,:,:));

erange = [0 1];
vrange = [0 1]; % changes the plot scaling (colours)

minfo = plotgraph3d(cohmat,'plotqt',plotqt,'escale',erange,'vscale',vrange,'cshift',0.4,...
    'numcolors',5,'arcs','strength','lhfactor',1);
fprintf('%s: %s band - number of modules: %d\n',basename,bands{bandidx},length(unique(minfo)));
set(gcf,'Name',sprintf('%s: %s band',basename,bands{bandidx}));

fprintf('Saving image.\n');
camva(8);
camtarget([-9.7975  -28.8277   41.8981]);
campos([-1.7547    1.7161    1.4666]*1000);
camzoom(1.25);
set(gcf,'InvertHardCopy','off');
print(gcf,sprintf('%s/figures/%s_%s_mohawk.tif',filepath,basename,bands{bandidx}),'-dtiff','-r150');

writerObj = VideoWriter(sprintf('%s/figures/%s_%s_mohawk.avi',filepath,basename,bands{bandidx}));
writerObj.FrameRate = 25; % How many frames per second.
open(writerObj);

angledelta = 2;
hold on

fprintf('Saving movie...');
for a = angledelta:angledelta:360
    camorbit(gca,angledelta,0);
    frame = getframe(gcf);
    writeVideo(writerObj, frame);
    
end
hold off
close(writerObj); % Saves the movie.
fprintf(' Done.\n');
end
