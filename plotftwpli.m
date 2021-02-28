function plotftwpli(basename)

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

savefile = sprintf('%s%s_mohawk.mat',filepath,basename);

specinfo = load(savefile);
figure('Name',basename,'Color','white'); hold all
plot(specinfo.freqs,mean(specinfo.chanwpli,1),'LineWidth',2);
set(gca,'XLim',[specinfo.freqs(1) specinfo.freqs(end)],'FontSize',fontsize,'FontName',fontname);

xlabel('Frequency (Hz)','FontSize',fontsize,'FontName',fontname);
ylabel('WPLI','FontSize',fontsize,'FontName',fontname);

for f = 1:4
    line([specinfo.freqlist(f,1) specinfo.freqlist(f,1)],ylim,'LineWidth',1,...
        'LineStyle','-.','Color','black');
    line([specinfo.freqlist(f,2) specinfo.freqlist(f,2)],ylim,'LineWidth',1,...
        'LineStyle','-.','Color','black');
%     text(specinfo.freqlist(f,1),ylimits(2),...
%         sprintf('\\%s',bands{f}),'FontName',fontname,'FontSize',fontsize);
end
box on

print(gcf,sprintf('%s/figures/%s_wpli.tif',filepath,basename),'-dtiff','-r150');
close(gcf);