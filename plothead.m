function plothead(basename,bandidx,varargin)

% Copyright (C) 2018 Srivas Chennu, University of Kent and University of Cambrige,
% srivas@gmail.com
% 
% 
% Plots and saves 3D connectivity topographs.
% 
% bandidx: specifies frequency band index to plot.
% (1 = delta, 2 = theta, 3 = alpha, 4 = beta, 5 = gamma) to
% 
% arcs: either - strength = colour arcs by strength of connectivity. - or -
% module = colour arcs by module affiliation.
% 
% movie: plot and save 'rotating head' movie of the 3D topograph.
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
    'arcs', 'string', {'strength','module'}, 'strength'; ...
    'movie', 'string', {'on','off'}, 'on'; ...    
    });

loadpaths

load([filepath filesep basename '_mohawk.mat']);

% proportion of strongest edges to plot
plotqt = 0.3;

% rescale edge weights to the range below before plotting
erange = [0 1];
% rescale vertex weights to the range below before plotting
vrange = [0 1];

bands = {
    'delta'
    'theta'
    'alpha'
    'beta'
    'gamma'
    };

cohmat = squeeze(matrix(bandidx,:,:));

minfo = plotgraph3d(cohmat,'plotqt',plotqt,'escale',erange,'vscale',vrange,'cshift',0.4,...
    'numcolors',5,'arcs',param.arcs,'lhfactor',1,'athick',.75);
fprintf('%s: %s band - number of modules: %d\n',basename,bands{bandidx},length(unique(minfo)));
set(gcf,'Name',sprintf('%s: %s band',basename,bands{bandidx}));

fprintf('Saving image.\n');
camva(8);
camtarget([-9.7975  -28.8277   41.8981]);
campos([-1.7547    1.7161    1.4666]*1000);
camzoom(1.25);
set(gcf,'InvertHardCopy','off');
print(gcf,sprintf('%s/figures/%s_%s_mohawk.tif',filepath,basename,bands{bandidx}),'-dtiff','-r300');

if strcmp(param.movie,'on')
    writerObj = VideoWriter(sprintf('%s/figures/%s_%s_mohawk.avi',filepath,basename,bands{bandidx}));
    writerObj.FrameRate = 25;
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
    close(writerObj);
    fprintf(' Done.\n');
end

end
