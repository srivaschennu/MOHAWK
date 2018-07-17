function plotftspec(basename,freqlist)

loadpaths

bands = {
    'delta'
    'theta'
    'alpha'
    'beta'
    'gamma'
    };

fontname = 'Helvetica';
fontsize = 28;
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
%     text(specinfo.freqlist(f,1),ylimits(2),...
%         sprintf('\\%s',bands{f}),'FontName',fontname,'FontSize',fontsize);
end
box on

print(gcf,sprintf('%s/figures/%s_spec.tif',filepath,basename),'-dtiff','-r150');
close(gcf);