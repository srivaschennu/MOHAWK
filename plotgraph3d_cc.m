function minfo = plotgraph3d(matrix,varargin)

% matrix - NxN symmetric connectivity matrix, where N is the number of channels
% chanlocs - 1xN EEGLAB chanlocs structure specifying channel locations

% OPTIONAL ARGUMENTS
% plotqt - proportion of strongest edges to plot
% minfo - 1xN module affiliation vector. Will be calculated if unspecified
% legend - whether or not to plot legend with max and min edge weights
% plotinter - whether or not to plot inter-modular edges

param = finputcheck(varargin, {
    'plotqt', 'real', [], 0.7; ...
    'minfo', 'integer', [], []; ...
    'plotinter', 'string', {'on','off'}, 'off'; ...
    'escale', 'real', [], []; ...
    'vscale', 'real', [], []; ...
    'view', 'real', [], []; ...
    'cshift', 'real', [], 0.4; ...
    'numcolors', 'real', [], 5; ...
    'lhfactor', 'real', [], 1; ...
    'arcs', 'string', {'strength','module'}, 'module'; ...    
    'athick', 'real', [], 0.75; ...    
    });

matrix(isnan(matrix)) = 0;

load(sprintf('sortedlocs_%d.mat',size(matrix,1)));

%keep only top <plotqt>% of weights
matrix = threshold_proportional(matrix,1-param.plotqt);

for c = 1:size(matrix,1)
    vsize(c) = sum(matrix(c,:))/(size(matrix,2)-1);
end

% calculate modules after thresholding edges
if isempty(param.minfo)
    minfo = community_louvain(matrix);
else
    minfo = param.minfo;
end

% rescale weights
if isempty(param.escale)
    param.escale(1) = min(matrix(logical(triu(matrix,1))));
    param.escale(2) = max(matrix(logical(triu(matrix,1))));
end
matrix = (matrix - param.escale(1))/(param.escale(2) - param.escale(1));
matrix(matrix < 0) = 0;

% rescale degrees
if isempty(param.vscale)
    param.vscale(1) = min(vsize);
    param.vscale(2) = max(vsize);
end
vsize = (vsize - param.vscale(1))/(param.vscale(2) - param.vscale(1));
vsize(vsize < 0) = 0;

% assign all modules with only one vertex the same colour
modsize = hist(minfo,unique(minfo));
num_mod = sum(modsize > 1);
modidx = 1;
newminfo = zeros(size(minfo));
for i = 1:length(newminfo)
    if newminfo(i) == 0
        if modsize(minfo(i)) == 1
            newminfo(i) = num_mod + 1;
        else
            newminfo(minfo == minfo(i)) = modidx;
            modidx = modidx + 1;
        end
    end
end
minfo = newminfo;
num_mod = length(unique(minfo));

cmap = lines;
colorlist = cmap([1 2 3 4 5 6],:);
colorlist = colorlist(1:num_mod,:);

while true
    
    clfig_h = figure;
    figpos = get(clfig_h,'Position');
    set(clfig_h,'Position',[0 0 figpos(3)/2,figpos(4)]);
    hold all
    
    for cl = 1:size(colorlist,1)
        plot([0 1],[cl cl],'LineWidth',5,'Color',colorlist(cl,:));
    end
    set(gca,'YTick',1:size(colorlist,1),'XTick',[]);
    
    figure('Color','black','Name',mfilename);
    figpos = get(gcf,'Position');
    set(gcf,'Position',[figpos(1) figpos(2) figpos(3)*1.25 figpos(4)*2],'Color','black');
    
    hold all
    
    if isempty(param.view)
        param.view = 'frontleft';
    end
    
    data2plot = zeros(1,length(allchanlocs));
    [~,chanidx] = ismember({sortedlocs.labels}',{allchanlocs.labels}');
    data2plot(chanidx) = vsize;
    
    [~,chanlocs3d] = headplot(data2plot,sprintf('allchanlocs_%d.spl',size(matrix,1)),'electrodes','off','maplimits',[-1 1]*(1-param.cshift),'view',param.view);
    chanlocs3d = chanlocs3d(chanidx,:);
    
    xlim('auto'); ylim('auto'); zlim('auto');
    
    for r = 1:size(matrix,1)
        for c = 1:size(matrix,2)
            if r < c && matrix(r,c) > 0
                eheight = (matrix(r,c)*param.lhfactor)+1;
                if minfo(r) == minfo(c)
                    ecol = colorlist(minfo(r),:);
                    hLine = plotarc3d(chanlocs3d([r,c],:),eheight,ecol,param.athick);
                elseif strcmp(param.plotinter,'on')
                    hLine = plotarc3d(chanlocs3d([r,c],:),eheight);
                    ecol = [0 0 0];
                    set(hLine,'Color',ecol,'LineWidth',0.1);
                end
            end
        end
    end
    
    resp = input('Enter color order, ENTER if OK: ','s');
    if isempty(resp)
        close(clfig_h);
        break;
    else
        close(clfig_h);
        close(gcf);
        colorlist = colorlist(eval([ '[' resp ']' ]),:);
        continue;
    end

end