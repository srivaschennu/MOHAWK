function plotauc(listname,varargin)

param = finputcheck(varargin, {
    'group', 'string', [], 'crsdiag'; ...
    'groupnames', 'cell', {}, {'UWS','MCS-','MCS+','EMCS','LIS','CTRL'}; ...
    'pairlist' 'real', [], [1 6]; ...
    'grouppairs' 'real', [], []; ...
    'xlim', 'real', [], []; ...
    'nonsig', 'string', {'on','off'}, 'on'; ...
    'plotcm', 'string', {'on','off'}, 'off'; ...
    'xlabel', 'string', [], ''; ...
    'ylabel', 'string', [], ''; ...
    'alpha', 'real', [], 0.05; ...
    'prefix', 'string', {'anoxic_','tbi_',''}, ''; ...
    });

if ~isstruct(param)
    error('Incorrect parameters specified.');
end

bands = {
    'delta'
    'theta'
    'alpha'
    };

groups = 0:length(param.groupnames)-1;
if isempty(param.grouppairs)
    grouppairs = [
        0 1
        1 2
        ];
else
    grouppairs = param.grouppairs;
end

% colorlist = [
%     0 0.0 0.5
%     0 0.5 0
%     0.5 0.0 0
%     0   0.5 0.5
%     0.5 0   0.5
%     0.5 0.5 0
%     ];
% 
% facecolorlist = [
%     0.75  0.75 1
%     0.25 1 0.25
%     1 0.75 0.75
%     0.75 1 1
%     1 0.75 1
%     1 1 0.75
%     ];

fontname = 'Helvetica';
fontsize = 24;

loadpaths

load(sprintf('%s/stats_%s_%s%s.mat',filepath,listname,param.prefix,param.group),'stats','featlist');

featlist = {
    'power'                  [1]    'Rel. power \delta'
    'power'                  [2]    'Rel. power \theta'
    'power'                  [3]    'Rel. power \alpha'
    'median'                 [1]    'Med. dwPLI \delta'
    'median'                 [2]    'Med. dwPLI \theta'
    'median'                 [3]    'Med. dwPLI \alpha'
    'clustering'             [1]    'Clust. coeff. \delta'
    'clustering'             [2]    'Clust. coeff. \theta'
    'clustering'             [3]    'Clust. coeff. \alpha'
    'characteristic path length'     [1]    'Char. path len. \delta'
    'characteristic path length'     [2]    'Char. path len. \theta'
    'characteristic path length'     [3]    'Char. path len. \alpha'
    'modularity'             [1]    'Modularity \delta'
    'modularity'             [2]    'Modularity \theta'
    'modularity'             [3]    'Modularity \alpha'
    'participation coefficient'     [1]    '\sigma(Part. coeff.) \delta'
    'participation coefficient'     [2]    '\sigma(Part. coeff.) \theta'
    'participation coefficient'     [3]    '\sigma(Part. coeff.)  \alpha'
    'modular span'           [1]    'Mod. span \delta'
    'modular span'           [2]    'Mod. span \theta'
    'modular span'           [3]    'Mod. span \alpha'
    };

if size(stats,2) > 2
    stats = stats(:,param.pairlist);
end


colorlist = [
    0 0 0
    ];
facecolorlist = [
    0.75 0.75 0.75
    ];

p_thresh = fdr(cell2mat({stats.pval}),param.alpha);
% p_thresh = 0.05;

markersizes = [200 400];

for g = 1:size(stats,2)
    
    figure('Color','white');
    hold all
        
    [~,sortidx] = sort(cell2mat({stats(:,g).auc}),'descend');
    yticklabels = {};
    for f = 1:10
        if stats(sortidx(f),g).pval < p_thresh
            markersize = markersizes(2);
        elseif stats(sortidx(f),g).pval < param.alpha
            markersize = markersizes(1);
        else
            continue;
        end
        
        legendoff(line([0.5 max(cell2mat({stats(sortidx(f),g).auc}))],[f f],'LineWidth',0.5,'Color',[0.5 0.5 0.5]));
        if f == 1
            sc_h(f,g) = scatter(stats(sortidx(f),g).auc,f,markersize,...
                'MarkerFaceColor',facecolorlist,'MarkerEdgeColor',colorlist,'LineWidth',1.5);
        else
            sc_h(f,g) = legendoff(scatter(stats(sortidx(f),g).auc,f,markersize,...
                'MarkerFaceColor',facecolorlist,'MarkerEdgeColor',colorlist,'LineWidth',1.5));
        end

        yticklabels = cat(1,yticklabels,featlist{sortidx(f),3});
    end
    
    set(gca,'FontName',fontname,'FontSize',fontsize,'YDir','reverse');
    if isempty(param.xlim)
        xlim([0.5 0.9]);
    else
        xlim(param.xlim);
    end
    grouppairnames = sprintf('%s vs. %s',param.groupnames{grouppairs(g,1)+1},param.groupnames{grouppairs(g,2)+1});
    xlabel(grouppairnames,'FontName',fontname,'FontSize',fontsize);
    set(gca,'YLim',[0.5 length(yticklabels)+0.5],'YTick',1:length(yticklabels),'YTickLabel',yticklabels);
    
    figpos = get(gcf,'Position');
    figpos(3) = figpos(3)*2;
    figpos(4) = figpos(4)*(1/6)*length(yticklabels);
    set(gcf,'Position',figpos);

    export_fig(sprintf('%s/figures/auc_%s_%s%s_%d.tiff',filepath,listname,param.prefix,param.group,g),'-r200','-p0.01');
    close(gcf);
end

%% plot confusion matrix of best classifier

if strcmp(param.plotcm,'on')
    fontsize = fontsize + 10;
    for g = 1:size(stats,2)
        [~,bestauc] = max(cell2mat({stats(:,g).auc}));
        
        fprintf('%s %s - %s vs %s: AUC = %.2f, p = %.5f, Chi2 = %.2f, Chi2 p = %.1e, accu = %d%%.\n',...
            featlist{bestauc,2},bands{featlist{bestauc,3}},param.groupnames{grouppairs(g,1)+1},param.groupnames{grouppairs(g,2)+1},...
            stats(bestauc,g).auc,stats(bestauc,g).pval,stats(bestauc,g).chi2,stats(bestauc,g).chi2pval,round(stats(bestauc,g).accu));
        
        plotconfusionmat(stats(bestauc,g).confmat,{param.groupnames{grouppairs(g,1)+1},param.groupnames{grouppairs(g,2)+1}});
        set(gca,'FontName',fontname,'FontSize',fontsize+4);
        if ~isempty(param.xlabel)
            xlabel(param.xlabel,'FontName',fontname,'FontSize',fontsize);
        else
            xlabel('EEG prediction','FontName',fontname,'FontSize',fontsize);
        end
        if ~isempty(param.ylabel)
            ylabel(param.ylabel,'FontName',fontname,'FontSize',fontsize);
        else
            ylabel('CRS-R diagnosis','FontName',fontname,'FontSize',fontsize);
        end
        
        export_fig(gcf,sprintf('%s/figures/clsyfyr_%s%s_%s_vs_%s_cm.tiff',filepath,param.prefix,param.group,param.groupnames{grouppairs(g,1)+1},param.groupnames{grouppairs(g,2)+1}),'-p0.01');
        close(gcf);
    end
end