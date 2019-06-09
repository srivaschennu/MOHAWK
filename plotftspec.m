function plotftspec(basename,freqlist)

% Copyright (C) 2018 Srivas Chennu, University of Kent and University of Cambrige,
% srivas@gmail.com
% 
% 
% Visualises and saves log power spectrum. Also displays windows
% demarcating canonical frequency bands (delta, theta, alpha, beta and
% gamma). These are loaded from the the file freqlist.mat. The canonical
% definitions can be modified if needed, by specifying the 'freqlist' input
% argument, specifying the window for each frequency band like below:
% [0  4; 4  8; 8  13; 13  30; 30  45]
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

loadpaths

bands = {
    'delta'
    'theta'
    'alpha'
    'beta'
    'gamma'
    };

fontname = 'Helvetica';
fontsize = 16;
xlim = [0.01 40];
ylim = [-50 15];

savefile = sprintf('%s%s_mohawk.mat',filepath,basename);

if exist('freqlist','var') && ~isempty(freqlist)
    save(savefile,'freqlist','-append');
else
    specinfo = load(savefile,'freqlist');
    fprintf('freqlist = %s\n',mat2str(specinfo.freqlist));
end

specinfo = load(savefile);
figure('Name',basename,'Color','white'); hold all
plot(specinfo.freqs,10*log10(specinfo.spectra'),'LineWidth',2);
set(gca,'XLim',xlim,'YLim',ylim,'FontSize',fontsize,'FontName',fontname);
xlabel('Frequency (Hz)','FontSize',fontsize,'FontName',fontname);
ylabel('Power (dB)','FontSize',fontsize,'FontName',fontname);
ylimits = ylim;
for f = 1:4
    line([specinfo.freqlist(f,1) specinfo.freqlist(f,1)],ylim,'LineWidth',1,...
        'LineStyle','-.','Color','black');
    line([specinfo.freqlist(f,2) specinfo.freqlist(f,2)],ylim,'LineWidth',1,...
        'LineStyle','-.','Color','black');
    text(specinfo.freqlist(f,1),ylimits(2),...
        sprintf('\\%s',bands{f}),'FontName',fontname,'FontSize',fontsize);
end
box on

print(gcf,sprintf('%s/figures/%s_spec.tif',filepath,basename),'-dtiff','-r150');
close(gcf);