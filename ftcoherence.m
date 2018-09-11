function ftcoherence(basename)

loadpaths

savefile = [filepath basename '_mohawk.mat'];

EEG = pop_loadset('filename',[basename '.set'],'filepath',filepath);

chanlocs = EEG.chanlocs;

load(sprintf('sortedlocs_%d.mat',length(chanlocs)));

load(savefile,'freqlist');

cpidx = 0;
for chann1 = 1:length(chanlocs)
    for chann2 = 1:length(chanlocs)
        if chann1 < chann2
            cpidx = cpidx + 1;
            chanpairs(cpidx,:) = [chann1 chann2];
        end
    end
end

EEG = convertoft(EEG);
cfg = [];
cfg.output     = 'powandcsd';
cfg.method     = 'mtmfft';
cfg.foilim        = [0.5 45];
cfg.taper = 'dpss';
cfg.tapsmofrq = 0.3;
cfg.keeptrials = 'yes';
cfg.pad='nextpow2';
numrand = 0;

EEG = ft_freqanalysis(cfg,EEG);

matrix = zeros(size(freqlist,1),length(chanlocs),length(chanlocs));
bootmat = zeros(size(freqlist,1),length(chanlocs),length(chanlocs),numrand);
coh = zeros(length(chanlocs),length(chanlocs));

elec = EEG.elec;

wpli = ft_connectivity_wpli(EEG.crsspctrm,'debias',true,'dojack',false);

for f = 1:size(freqlist,1)
    [~, bstart] = min(abs(EEG.freq-freqlist(f,1)));
    [~, bend] = min(abs(EEG.freq-freqlist(f,2)));
    [~,freqidx] = max(mean(wpli(:,bstart:bend),1));
    
    coh(:) = 0;
    coh(logical(tril(ones(size(coh)),-1))) = wpli(:,bstart+freqidx-1);
    coh = tril(coh,1)+tril(coh,1)';
    
    matrix(f,:,:) = coh;
end
fprintf('\n');

[sortedchan,sortidx] = sort({chanlocs.labels});
if ~strcmp(chanlist,cell2mat(sortedchan))
    error('Channel names do not match!');
end
matrix = matrix(:,sortidx,sortidx);
bootmat = bootmat(:,sortidx,sortidx,:);

chanwpli = zeros(length(chanlocs),size(wpli,2));
for c = 1:length(chanlocs)
    chanwpli(c,:) = mean(wpli(chanpairs(:,1) == c | chanpairs(:,2) == c,:),1);
end
chanwpli = chanwpli(sortidx,:);

save(savefile,'wpli','chanpairs','chanwpli','elec','matrix','bootmat','-append');
fprintf('\nDone.\n');
