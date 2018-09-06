function calcwsmi(basename)

loadpaths

%%% The output variables are structured in cells corresponding 
%%% to each tau.
%%%
%%% Variables:
%%%
%%% sym: the symbolic transformation of the time series (carefull is zero based, symbols form 0 to 5). 
%%% Structure: channel x symbols x trials
%%%
%%% count: the probability (ocurrence rate) of each symbol.
%%% Structure: channel x symbols x trials
%%%
%%% smi: the symbolic mutual information connectivity 
%%% Structure:
%%% channels x channels x trials, with the connectivity between channels
%%%
%%% wsmi: idem to smi but weighted

EEG = pop_loadset('filepath',rawpath,'filename',[basename '_clean.set']);
% if EEG.nbchan == 92
%     EEG = pop_select(EEG,'nochannel',{'E57','E100'});
% elseif EEG.nbchan == 174
    EEG = pop_select(EEG,'nochannel',{'E94','E190'});
% end
EEG = rereference(EEG,5,[],'_csd');

chanlocs = EEG.chanlocs;
load(sprintf('sortedlocs_%d.mat',length(chanlocs)));

EEG.data = reshape(reshape(EEG.data,EEG.nbchan,EEG.pnts*EEG.trials),...
    EEG.nbchan,EEG.pnts/5,EEG.trials*5);

wsmicfg.chan_sel = 1:size(EEG.data,1);  % compute for all pairs of channels
wsmicfg.data_sel = 1:size(EEG.data,2); % compute using all samples
wsmicfg.taus     = [32 16 8 4 2]; % compute for taus
wsmicfg.kernel   = 3; % kernel = 3 (3 samples per symbol)
wsmicfg.sf       = EEG.srate;  % sampling frequency
wsmicfg.over_trials = 0;  % sampling frequency

[~, ~, ~, wsmi] = smi_and_wsmi(EEG.data, wsmicfg);

for t = 1:length(wsmi)
    wsmi{t} = mean(wsmi{t},3);
    wsmi{t}(wsmi{t} < 0) = 0;
    wsmi{t} = triu(wsmi{t},1)+triu(wsmi{t},1)';
end
wsmi = permute(cat(3,wsmi{:}),[3 1 2]);

[sortedchan,sortidx] = sort({chanlocs.labels});
if ~strcmp(chanlist,cell2mat(sortedchan))
    error('Channel names do not match!');
end
wsmi = wsmi(:,sortidx,sortidx);

wsmicfg.taus = (EEG.srate/wsmicfg.kernel)./wsmicfg.taus;
save([filepath basename '_mohawk.mat'], 'wsmi', 'wsmicfg','-append');

