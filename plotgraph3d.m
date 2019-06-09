function minfo = plotgraph3d(matrix,varargin)

% Copyright (C) 2018 Srivas Chennu, University of Kent and University of Cambrige,
% srivas@gmail.com
% 
% 
% plots 3D connectivity topograph.
% matrix - NxN symmetric connectivity matrix, where N is the number of channels

% OPTIONAL ARGUMENTS
% plotqt - proportion of strongest edges to plot
% minfo - 1xN module affiliation vector. Will be estimated if not specified
% legend - whether or not to plot legend with max and min edge weights
% plotinter - whether or not to plot inter-modular edges
% 
%
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
% 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <https://www.gnu.org/licenses/>.



param = finputcheck(varargin, {
    'plotqt', 'real', [], 0.3; ...
    'lhfactor', 'real', [], 1.25; ...
    'minfo', 'integer', [], []; ...
    'plotinter', 'string', {'on','off'}, 'off'; ...
    'escale', 'real', [], []; ...
    'vscale', 'real', [], []; ...
    'view', 'real', [], []; ...
    'cshift', 'real', [], 0.4; ...
    'numcolors', 'real', [], 5; ...
    'arcs', 'string', {'strength','module'}, 'strength'; ...
    'athick', 'real', [], 0.75; ...    
    });

matrix(isnan(matrix)) = 0;

load(sprintf('sortedlocs_%d.mat',size(matrix,1)));

%keep only top <plotqt>% of weights
matrix = threshold_proportional(matrix,param.plotqt);

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

figure('Color','black','Name',mfilename);
figpos = get(gcf,'Position');
set(gcf,'Position',[figpos(1) figpos(2) figpos(3)*1.5 figpos(4)*2],'Color','black');
if strcmp(param.arcs,'strength')
    cmap = jet;
elseif strcmp(param.arcs,'module')
    cmap = lines;
end
colorlist = cmap(1:param.numcolors,:);

hold all

if isempty(param.view)
    param.view = 'frontleft';
end

data2plot = zeros(1,length(allchanlocs));
[~,chanidx] = ismember({sortedlocs.labels}',{allchanlocs.labels}');
data2plot(chanidx) = vsize;

[~,chanlocs3d] = headplot(data2plot,sprintf('allchanlocs_%d.spl',size(matrix,1)),...
    'electrodes','off','maplimits',[-1 1]*(1-param.cshift),'view',param.view);

% The code below can be used to load a custom head mesh estimated from an
% MRI scan.
% load /Users/chennu/gdrive/MR_Meditation/MR_mesh.mat
% [~,chanlocs3d] = headplot(data2plot,'/Users/chennu/gdrive/MR_Meditation/MR.spl',...
%     'electrodes','off','maplimits',[-1 1]*(1-param.cshift),'view',param.view,'meshfile',MR_mesh);

chanlocs3d = chanlocs3d(chanidx,:);

xlim('auto'); ylim('auto'); zlim('auto');

cidx = round(matrix .* size(cmap,1));
cidx(cidx <= 0) = 1;
cidx(cidx > size(cmap,1)) = size(cmap,1);

for r = 1:size(matrix,1)
    for c = 1:size(matrix,2)
        if r < c && matrix(r,c) > 0
            eheight = (matrix(r,c)*param.lhfactor)+1;
            if minfo(r) == minfo(c)
                if strcmp(param.arcs,'strength')
                    ecol = cmap(cidx(r,c),:);
                elseif strcmp(param.arcs,'module')
                    ecol = colorlist(minfo(r),:);
                end
                plotarc3d(chanlocs3d([r,c],:),eheight,ecol,param.athick);
            elseif strcmp(param.plotinter,'on')
                plotarc3d(chanlocs3d([r,c],:),eheight,[0 0 0],param.athick);
            end
        end
    end
end