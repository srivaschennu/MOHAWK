function [scores,group,stats] = plotmeasure(listname,measure,bandidx,varargin)

param = finputcheck(varargin, {
    'group', 'string', [], 'crsdiag'; ...
    'face', 'string', [], ''; ...
    'groupnames', 'cell', {}, {'UWS','MCS-','MCS+','EMCS','LIS','CTRL'}; ...
    'changroup', 'string', [], 'allchan'; ...
    'changroup2', 'string', [], 'allchan'; ...
    'xlabel', 'string', [], ''; ...
    'ylabel', 'string', [], measure; ...
    'xlim', 'real', [], []; ...
    'ylim', 'real', [], []; ...
    'xtick', 'real', [], []; ...
    'ytick', 'real', [], []; ...
    'legend', 'string', {'on','off'}, 'off'; ...
    'legendlocation', 'string', [], 'Best'; ...
    'noplot', 'string', {'on','off'}, 'off'; ...
    'plotcm', 'string', {'on','off'}, 'off'; ...
    });

fontname = 'Helvetica';
fontsize = 24;

loadpaths
changroups

load(sprintf('%s/groupdata_%s.mat',filepath,listname),'allcoh','subjlist');
load(sprintf('sortedlocs_%d.mat',size(allcoh,3)));
if strcmp(param.changroup,'allchan')
    param.changroup = sprintf('%s_%d',param.changroup,size(allcoh,3));
end
if strcmp(param.changroup2,'allchan')
    param.changroup2 = sprintf('%s_%d',param.changroup2,size(allcoh,3));
end

groupvar = subjlist.(param.group);

groups = unique(groupvar(~isnan(groupvar)));

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
plottvals = [];

if strcmpi(measure,'power')
    load(sprintf('%s/groupdata_%s.mat',filepath,listname),'bandpower');
    testdata = mean(bandpower(:,bandidx,ismember({sortedlocs.labels},eval(param.changroup))),3) * 100;
elseif strcmpi(measure,'specent')
    load(sprintf('%s/groupdata_%s.mat',filepath,listname),'specent');
    testdata = mean(specent(:,ismember({sortedlocs.labels},eval(param.changroup))),2);
elseif strcmpi(measure,'median')
    load(sprintf('%s/groupdata_%s.mat',filepath,listname),'allcoh');
    testdata = median(median(allcoh(:,bandidx,ismember({sortedlocs.labels},eval(param.changroup)),ismember({sortedlocs.labels},eval(param.changroup2))),4),3);
elseif strcmpi(measure,'wsmi')
    load(sprintf('%s/groupdata_%s.mat',filepath,listname),'allwsmi');
    testdata = median(median(allwsmi(:,bandidx,ismember({sortedlocs.labels},eval(param.changroup)),ismember({sortedlocs.labels},eval(param.changroup2))),4),3);
elseif strcmpi(measure,'mean')
    load(sprintf('%s/groupdata_%s.mat',filepath,listname),'allcoh');
    testdata = mean(mean(allcoh(:,bandidx,ismember({sortedlocs.labels},eval(param.changroup)),ismember({sortedlocs.labels},eval(param.changroup2))),4),3);
elseif strcmpi(measure,'refdiag') || strcmpi(measure,'crs') || strcmpi(measure,'auditory') || strcmpi(measure,'visual') || strcmpi(measure,'motor') || ...
        strcmpi(measure,'verbal') || strcmpi(measure,'communication') || strcmpi(measure,'arousal') || strcmpi(measure,'etiology')
    testdata = subjlist.(measure);
else
    trange = [0.9 0.1];
    load(sprintf('%s/groupdata_%s.mat',filepath,listname),'graph','tvals');
    trange = (tvals <= trange(1) & tvals >= trange(2));
    plottvals = tvals(trange);
    
    m = find(strcmpi(measure,graph(:,1)));
    if strcmpi(measure,'modules')
        testdata = squeeze(max(graph{m,weiorbin}(:,bandidx,trange,:),[],4));
    elseif strcmpi(measure,'centrality')
        testdata = squeeze(std(graph{m,weiorbin}(:,bandidx,trange,:),[],4));
    elseif strcmpi(measure,'mutual information')
        % mutual information to controls
        testdata = squeeze(nanmean(graph{m,weiorbin}(:,groupvar == 5,bandidx,trange),2));
    elseif strcmpi(measure,'participation coefficient') || strcmpi(measure,'degree')
        testdata = squeeze(std(graph{m,weiorbin}(:,bandidx,trange,ismember({sortedlocs.labels},eval(param.changroup))),[],4));
    else
        testdata = squeeze(mean(graph{m,weiorbin}(:,bandidx,trange,:),4));
    end
end

bands = {
    'delta'
    'theta'
    'alpha'
    'beta'
    'gamma'
    };

if strcmp(param.noplot,'off')
    for g = 1:length(groups)
        plotdata = mean(testdata(groupvar == groups(g),:,:),3);
        groupmean(g,:) = nanmean(plotdata,1);
        groupste(g,:) = nanstd(plotdata,[],1)./sqrt(size(plotdata,1));
    end
    
    if ~isempty(plottvals)
        %% plot graph across connection densities
        
        figure('Color','white');
        hold all
        set(gca,'XDir','reverse');
        for g = 1:length(groups)
            errorbar(plottvals,groupmean(g,:),groupste(g,:),'LineWidth',1,'Color',colorlist(g,:));
        end
        set(gca,'XLim',[plottvals(end)-0.01 plottvals(1)+0.01],'FontName',fontname,'FontSize',fontsize);
        xlabel('Graph connection density','FontName',fontname,'FontSize',fontsize);
        ylabel(param.ylabel,'FontName',fontname,'FontSize',fontsize);
        if ~isempty(param.ylim)
            set(gca,'YLim',param.ylim);
        end
        legend(groupnames(groups+1),'Location',param.legendlocation);
        print(gcf,sprintf('%s/figures/%s_%s_%s.tiff',filepath,measure,bands{bandidx},param.group),'-dtiff','-r300');
        close(gcf);
    end
end

groups = unique(groupvar(~isnan(groupvar)));
grouppairs = nchoosek(groups,2);

for g = 1:size(grouppairs,1)
    grouppairnames{g} = sprintf('%s-%s',groupnames{groups == grouppairs(g,1)},groupnames{groups == grouppairs(g,2)});
    thisgroupvar = groupvar(groupvar == grouppairs(g,1) | groupvar == grouppairs(g,2));
    [~,~,thisgroupvar] = unique(thisgroupvar);
    thisgroupvar = thisgroupvar-1;
    thistestdata = testdata(groupvar == grouppairs(g,1) | groupvar == grouppairs(g,2),:,:);
    
    for d = 1:size(thistestdata,2)
        thistestdata2 = squeeze(thistestdata(:,d,:));
        
        [x,y,t,auc(g,d)] = perfcurve(thisgroupvar, thistestdata2,1);
        if auc(g,d) < 0.5
            auc(g,d) = 1-auc(g,d);
        end
        
        [~,bestthresh] = max(abs(y + (1-x) - 1));
        %         [~,bestthresh] = min(sqrt((0-x).^2 + (1-y).^2));
        thisconfmat = confusionmat(thisgroupvar,double(thistestdata(:,d) > t(bestthresh)));
        [~,chi2(g,d),chi2pval(g,d)] = crosstab(thisgroupvar,double(thistestdata(:,d) > t(bestthresh)));
        accu(g,d) = sum(thisgroupvar == double(thistestdata(:,d) > t(bestthresh)))*100/length(thisgroupvar);
        confmat(g,d,:,:) = thisconfmat;
        [pval(g,d),~,stat] = ranksum(thistestdata(thisgroupvar == 0,d),thistestdata(thisgroupvar == 1,d));
        n0 = sum(thisgroupvar == 0); n1 = sum(thisgroupvar == 1);
        U(g,d) = (n0*n1)+(n0*(n0+1))/2-stat.ranksum;
        U(g,d) = min(U(g,d),(n0*n1) - U(g,d));
    end
    
    [~,maxaucidx] = max(auc(g,:));
    stats(g).U = U(g,maxaucidx);
    stats(g).auc = auc(g,maxaucidx);
    stats(g).pval = pval(g,maxaucidx);
    stats(g).confmat = squeeze(confmat(g,maxaucidx,:,:));
    stats(g).maxaucidx = maxaucidx;
    stats(g).chi2 = chi2(g,maxaucidx);
    stats(g).chi2pval = chi2pval(g,maxaucidx);
    stats(g).accu = accu(g,maxaucidx);
    
    if strcmp(param.noplot,'off')
        fprintf('%s %s: %s vs %s AUC = %.2f, J = %.2f, p = %.4f.\n',measure,bands{bandidx},...
            param.groupnames{grouppairs(g,1)+1},param.groupnames{grouppairs(g,2)+1},...
            auc(g,maxaucidx),(thisconfmat(2,2) + thisconfmat(1,1))/100 - 1, pval(g,maxaucidx));
        if strcmp(param.plotcm,'on')
            plotconfusionmat(squeeze(confmat(g,maxaucidx,:,:)),{param.groupnames{grouppairs(g,1)+1},param.groupnames{grouppairs(g,2)+1}});
            set(gca,'FontName',fontname,'FontSize',fontsize);
            if ~isempty(param.xlabel)
                xlabel(param.xlabel,'FontName',fontname,'FontSize',fontsize);
            else
                xlabel('EEG diagnosis','FontName',fontname,'FontSize',fontsize);
            end
            if ~strcmp(param.ylabel,measure)
                ylabel(param.ylabel,'FontName',fontname,'FontSize',fontsize);
            else
                ylabel('CRS-R diagnosis','FontName',fontname,'FontSize',fontsize);
            end
            print(gcf,sprintf('%s/figures/%s_vs_%s_%s_cm.tiff',filepath,param.groupnames{grouppairs(g,1)+1},param.groupnames{grouppairs(g,2)+1},measure),'-dtiff');
            close(gcf);
        end
    end
end

if strcmp(param.noplot,'off')
    %% plot mean graph
    figure('Color','white');
        figpos = get(gcf,'Position');
    if length(groups) == 2
        figpos(3) = figpos(3)*1/2;
    elseif length(groups) == 3
        figpos(3) = figpos(3)*2/3;
    end
    set(gcf,'Position',figpos);
    
    hold all
    
    if isempty(param.face)
        boxh = notBoxPlot(nanmean(testdata,2),groupvar+1,0.5,'patch',ones(size(testdata,1),1));
    else
        boxh = notBoxPlot(nanmean(testdata,2),groupvar+1,0.5,'patch',eval(param.face));
    end
    
    if length(groups) > 2
        jttestdata = nanmean(testdata(groupvar < 5,:),2);
        jtgroupvar = groupvar(groupvar < 5) + 1;
        [jtgroupvar,sortidx] = sort(jtgroupvar);
        jttestdata = jttestdata(sortidx);
        [~,JT,pval] = evalc('jttrend([jttestdata jtgroupvar])');
        if pval < 0.0001
            fprintf('\nJonckheere-Terpstra JT = %.2f, p = %.1e.\n',JT,pval);
        else
            fprintf('\nJonckheere-Terpstra JT = %.2f, p = %.4f.\n',JT,pval);
        end
    end
    
    for h = 1:length(boxh)
        set(boxh(h).data,'Color',colorlist(h,:),'MarkerFaceColor',facecolorlist(h,:))
    end
    set(gca,'XLim',[0.5 max(groups)+1.5],'XTick',1:max(groups)+1,...
        'XTickLabel',groupnames','FontName',fontname,'FontSize',fontsize);
    ylabel(param.ylabel,'FontName',fontname,'FontSize',fontsize);
    if ~isempty(param.ylim)
        set(gca,'YLim',param.ylim);
    end
    if ~isempty(param.ytick)
        set(gca,'YTick',param.ytick);
    end
    set(gcf,'Color','white');
    if ~isempty(param.ylim)
        ylim(param.ylim);
    end
    if strcmp(param.legend,'off')
        legend('hide');
    end
    box off
    print(gcf,sprintf('%s/figures/avg_%s_%s_%s.tiff',filepath,measure,bands{bandidx},param.group),'-dtiff','-r300');
    close(gcf);
    
    %% plot auc
    figure('Color','white');
    hold all
    if ~isempty(plottvals)
        set(gca,'XDir','reverse');
        for g = 1:size(grouppairs,1)
            plot(plottvals,auc(g,:),'LineWidth',2);
        end
        set(gca,'XLim',[plottvals(end) plottvals(1)]);
        xlabel('Graph connection density','FontName',fontname,'FontSize',fontsize);
        legend(grouppairnames,'Location',param.legendlocation);
        ylabel('AUC','FontName',fontname,'FontSize',fontsize);
        if ~isempty(param.ylim)
            set(gca,'YLim',param.ylim);
        else
            set(gca,'YLim',[0 1]);
        end
    else
        barh(auc(:,maxaucidx));
        ylim([0.5 size(auc,1)+0.5]);
        set(gca,'YTick',1:length(grouppairnames),'YTickLabels',grouppairnames);
        if ~isempty(param.xlim)
            set(gca,'XLim',param.ylim);
        else
            set(gca,'XLim',[0 1]);
        end
        xlabel('AUC','FontName',fontname,'FontSize',fontsize);
        xlimits = xlim;
        set(gca,'XTick',xlimits(1):0.1:xlimits(2),'YDir','reverse');
    end
    set(gca,'FontName',fontname,'FontSize',fontsize);
    
    print(gcf,sprintf('%s/figures/auc_%s_%s_%s.tiff',filepath,measure,bands{bandidx},param.group),'-dtiff','-r300');
    close(gcf);
    
end

scores = testdata;
group = groupvar;