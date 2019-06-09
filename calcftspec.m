function calcftspec(basename)

% Copyright (C) 2018 Srivas Chennu, University of Kent and University of Cambrige,
% srivas@gmail.com
% 
% Estimates channel-wise power spectrum using the multi-taper method.
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

load freqlist.mat

EEG = pop_loadset([filepath basename '.set']);
chanlocs = EEG.chanlocs;

load(sprintf('sortedlocs_%d.mat',length(chanlocs)));

EEG = convertoft(EEG);

cfg = [];
cfg.output     = 'pow';
cfg.method     = 'mtmfft';
cfg.foilim        = [0.5 45];
cfg.taper = 'dpss';
cfg.tapsmofrq = 0.3;
cfg.pad='nextpow2';

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
    
