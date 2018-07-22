function calcdiff(basenames)

loadpaths

savefile = [filepath basenames{1} '_mohawk.mat'];
load(savefile,'freqlist');

cfg = [];
cfg.output     = 'powandcsd';
cfg.method     = 'mtmfft';
cfg.foilim        = freqlist(3,:);
cfg.taper = 'dpss';
cfg.tapsmofrq = 0.3;
cfg.keeptrials = 'yes';
cfg.pad='nextpow2';

numrand = 10;

for s = 1:2
    EEG{s} = pop_loadset('filename',[basenames{s} '.set'],'filepath',filepath);
    EEG{s} = convertoft(EEG{s});   
    EEG{s} = ft_freqanalysis(cfg,EEG{s});    
end

if size(EEG{1}.crsspctrm,1) ~= size(EEG{2}.crsspctrm,1)
    error('Unequal number of epochs');
end
crsspctrm = cat(1,EEG{1}.crsspctrm,EEG{2}.crsspctrm);

wplidiff = zeros(numrand+1,size(EEG{1}.labelcmb,1));
fprintf('Starting...\n');

for n = 1:numrand+1
    if n > 1
        if n == 2
            fprintf('Running randomisation %d', n-1);
        else
            sranditer = sprintf('%d', n-1);
            fprintf(repmat('\b',1,length(sranditer)));
            fprintf('%s',sranditer);
        end
        crsspctrm = crsspctrm(randperm(size(crsspctrm,1)),:,:);
    end
    
    wpli = ft_connectivity_wpli(crsspctrm(1:size(EEG{1}.crsspctrm,1),:,:),'debias',true,'dojack',false);
    [~,freqidx] = max(mean(wpli,1));
    wplidiff(n,:) = wpli(:,freqidx)';
    
    wpli = ft_connectivity_wpli(crsspctrm(size(EEG{1}.crsspctrm,1)+1:end,:,:),'debias',true,'dojack',false);
    [~,freqidx] = max(mean(wpli,1));
    wplidiff(n,:) = wplidiff(n,:) - wpli(:,freqidx)';
end

pdist = max(wplidiff,[],2);

meandiff = repmat(mean(wplidiff,1),size(wplidiff,1),1);
stddiff = repmat(std(wplidiff,[],1),size(wplidiff,1),1);
wplidiff = (wplidiff - meandiff) ./ (stddiff / sqrt(numrand+1));

matrix = zeros(size(freqlist,1),length(chanlocs),length(chanlocs));
bootmat = zeros(size(freqlist,1),length(chanlocs),length(chanlocs),numrand);
coh = zeros(length(chanlocs),length(chanlocs));

freq = EEG.freq;
elec = EEG.elec;



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

save(savefile,'chanwpli','freq','elec','matrix','bootmat','-append');
fprintf('\nDone.\n');
