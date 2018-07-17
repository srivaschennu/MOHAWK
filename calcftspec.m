function calcftspec(basename)

loadpaths

load freqlist.mat

EEG = pop_loadset([filepath basename '.set']);
chanlocs = EEG.chanlocs;

load(sprintf('sortedlocs_%d.mat',length(chanlocs)));

mintrials = 50;
if EEG.trials < mintrials
    error('Need at least %d trials for analysis, only found %d.',mintrials,EEG.trials);
end

EEG = convertoft(EEG);

cfg = [];
cfg.output     = 'pow';
cfg.method     = 'mtmfft';
cfg.foilim        = [0.01 40];
% cfg.taper = 'rectwin';
cfg.taper = 'dpss';
cfg.tapsmofrq = 0.3;

EEG = ft_freqanalysis(cfg,EEG);
spectra = EEG.powspctrm;
freqs = EEG.freq;

[sortedchan,sortidx] = sort({chanlocs.labels});
if ~strcmp(chanlist,cell2mat(sortedchan))
    error('Channel names do not match!');
end
spectra = spectra(sortidx,:);
chanlocs = chanlocs(sortidx);

bpower = zeros(size(freqlist,1),length(chanlocs));
for f = 1:size(freqlist,1)
    [~, bstart] = min(abs(freqs-freqlist(f,1)));
    [~, bstop] = min(abs(freqs-freqlist(f,2)));
    [~,peakindex] = max(mean(spectra(:,bstart:bstop),1),[],2);
    bpower(f,:) = spectra(:,bstart+peakindex-1);
end
for c = 1:size(bpower,2)
    bpower(:,c) = bpower(:,c)./sum(bpower(:,c));
end

savefile = sprintf('%s%s_mohawk.mat',filepath,basename);

if exist(savefile,'file')
    save(savefile, 'chanlocs', 'freqs', 'spectra', 'freqlist', 'bpower', '-append');
else
    save(savefile, 'chanlocs', 'freqs', 'spectra', 'freqlist', 'bpower');
end
    
