function plotbands(basename,measure,varargin)

listname = 'allsubj';
bandidx = [1 2 3];

loadpaths

param = finputcheck(varargin, {
    'legend', 'string', {'on','off'}, 'on'; ...
    'title', 'string', {}, measure; ...
    'legendposition', 'string', {}, 'best'; ...
    });

fontname = 'Helvetica';
fontsize = 24;

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

groups = [0 1 5];
groupnames = {
    'UWS'
    'MCS'
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
elseif strcmp(measure,'power')
    load(sprintf('%s/%s_mohawk.mat',filepath,basename),'freqs');
    groupvals = mean(bandpower(:,bandidx,:),3);
    for f = 1:size(freqlist,1)
        %collate spectral info
        [~, bstart] = min(abs(freqs-freqlist(f,1)));
        [~, bstop] = min(abs(freqs-freqlist(f,2)));
        patvals(f,:) = mean(spectra(:,bstart:bstop),2);
    end
    for c = 1:size(patvals,2)
        patvals(:,c) = patvals(:,c)./sum(patvals(:,c));
    end
    patvals = mean(patvals(bandidx,:),2);
else
    groupvals = squeeze(mean(mean(graph{m,weiorbin}(selpatidx,bandidx,trange,:),4),3));
    patvals = squeeze(mean(mean(graphdata{m,weiorbin}(bandidx,trange,:),3),2));
end

plotvals = cat(1,groupvals,patvals');
groupnames = cat(1,groupnames,{'Patient'});

plotgroups = [grp(selpatidx); max(grp(selpatidx))+1];
uniqgroups = unique(plotgroups);

figure('Color','white','Name',basename);

for g = 1:length(uniqgroups)
    meanvals = mean(plotvals(plotgroups == uniqgroups(g),:),1);
    if size(plotvals(plotgroups == uniqgroups(g),:),1) > 1
        semvals = std(plotvals(plotgroups == uniqgroups(g),:),[],1) ./ ...
            sqrt(size(plotvals(plotgroups == uniqgroups(g),:),1));
    else
        xlimits = xlim; ylimits = ylim; zlimits = zlim;
        semvals = 0.05 * [xlimits(2)-xlimits(1) ylimits(2) - ylimits(1) zlimits(2) - zlimits(1)];
    end
    [x,y,z] = sphere;
    surf((x * semvals(1)) + meanvals(1),...
        (y * semvals(2)) + meanvals(2),...
        (z * semvals(3)) + meanvals(3),...
        'EdgeColor',colorlist(g,:),'FaceColor',facecolorlist(g,:),...
        'EdgeAlpha',0.5,'FaceAlpha',0.5);
    hold all
end
xlabel(sprintf('%s',bands{bandidx(1)}),'FontName',fontname,'FontSize',fontsize);
ylabel(sprintf('%s',bands{bandidx(2)}),'FontName',fontname,'FontSize',fontsize);
zlabel(sprintf('%s',bands{bandidx(3)}),'FontName',fontname,'FontSize',fontsize);
set(gca,'FontName',fontname,'FontSize',fontsize);
legend(groupnames,'Location',param.legendposition);

title(param.title,'FontName',fontname,'FontSize',fontsize);
print(gcf,sprintf('%s/figures/%s_%s.tif',filepath,basename,measure),'-dtiff','-r150');
close(gcf);