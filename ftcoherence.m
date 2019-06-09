function ftcoherence(basename)

% Copyright (C) 2018 Srivas Chennu, University of Kent and University of Cambrige,
% srivas@gmail.com
% 
% 
% Estimates dwPLI connectivity between pairs of channels in canonical
% frequency bands specified in the file freqlist.mat.
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
    
    % within each frequency band, identify peak of average connectivity
    % over all channel pairs, and use this peak frequency for  
    % recording the connectivity between each pair
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

% also save the average connectivity of each channel
chanwpli = zeros(length(chanlocs),size(wpli,2));
for c = 1:length(chanlocs)
    chanwpli(c,:) = mean(wpli(chanpairs(:,1) == c | chanpairs(:,2) == c,:),1);
end
chanwpli = chanwpli(sortidx,:);

save(savefile,'wpli','chanpairs','chanwpli','elec','matrix','bootmat','-append');
fprintf('\nDone.\n');
