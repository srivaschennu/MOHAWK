function calcdiff(basenames)

loadpaths

savefile = [filepath basenames{1} '_mohawk.mat'];
load(savefile,'freqlist','chanlocs');

cfg = [];
cfg.output     = 'powandcsd';
cfg.method     = 'mtmfft';
cfg.foilim        = freqlist(3,:);
cfg.taper = 'dpss';
cfg.tapsmofrq = 0.3;
cfg.keeptrials = 'yes';
cfg.pad='nextpow2';

stats.numrand = 200;

load(sprintf('sortedlocs_%d.mat',length(chanlocs)));

for s = 1:2
    EEG{s} = pop_loadset('filename',[basenames{s} '.set'],'filepath',filepath);
    [sortedchan,sortidx] = sort({EEG{s}.chanlocs.labels});
    if ~strcmp(chanlist,cell2mat(sortedchan))
        error('Channel names do not match!');
    end
    EEG{s}.chanlocs = EEG{s}.chanlocs(sortidx);
    EEG{s}.data = EEG{s}.data(sortidx,:,:);
    
    EEG{s} = convertoft(EEG{s});   
    EEG{s} = ft_freqanalysis(cfg,EEG{s});    
end

if size(EEG{1}.crsspctrm,1) ~= size(EEG{2}.crsspctrm,1)
    error('Unequal number of epochs');
end
crsspctrm = cat(1,EEG{1}.crsspctrm,EEG{2}.crsspctrm);

stats.numchan = size(EEG{1}.powspctrm,2);

stats.wplidiff = zeros(stats.numrand+1,(stats.numchan*stats.numchan - stats.numchan)/2);
fprintf('Starting... ');

for n = 1:stats.numrand+1
    if n > 1
        if n == 2
            fprintf('randomisation ');
        else
            fprintf(repmat('\b',1,length(sranditer)));
        end
        sranditer = sprintf('%d', n-1);
        fprintf('%s',sranditer);
        
        crsspctrm = crsspctrm(randperm(size(crsspctrm,1)),:,:);
    end
    
    wpli = ft_connectivity_wpli(crsspctrm(1:size(EEG{1}.crsspctrm,1),:,:),'debias',true,'dojack',false);
    [~,freqidx] = max(mean(wpli,1));
    stats.wplidiff(n,:) = wpli(:,freqidx)';
    
    wpli = ft_connectivity_wpli(crsspctrm(size(EEG{1}.crsspctrm,1)+1:end,:,:),'debias',true,'dojack',false);
    [~,freqidx] = max(mean(wpli,1));
    stats.wplidiff(n,:) = stats.wplidiff(n,:) - wpli(:,freqidx)';
end
fprintf(' done.\n');

save('diff_stats.mat','stats');