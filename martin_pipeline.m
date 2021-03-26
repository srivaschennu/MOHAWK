% Put this file pipeline.m in the same location as the MOHAWK software .m
% files

%%
% Change this to the location where the MOHAWK software data files are
% stored
filepath = '/Volumes/bigdisk/Data/MOHAWK/';

% Change this to the path where EEGLAB is installed
eeglabpath = '/Users/chennu/MATLAB/eeglab/';

%%

filename = '1_pre.fif';
basename = strtok(filename, '.');

%%
EEG = pop_fileio([filepath filename]);

%%
for i = 1:length(EEG.chanlocs)
    EEG.chanlocs(i).labels = EEG.chanlocs(i).labels(5:end);
end

%%
EEG.data = EEG.data * 10^6;

%%
EEG=pop_chanedit(EEG, 'lookup',[eeglabpath 'plugins/dipfit2.3/standard_BESA/standard-10-5-cap385.elp']);

%%
EEG = pop_reref( EEG, []);

%%
EEG.setname = basename;

%%
pop_saveset(EEG, 'filename', [basename '.set'], 'filepath', filepath);

%%
% Before running this step, change this line in calcftspec.m from cfg.tapsmofrq = 0.3 to cfg.tapsmofrq = 0.4
calcftspec(basename);

%%
plotftspec(basename);

%%
% Before running this step, change this line in ftcoherence.m from cfg.tapsmofrq = 0.3 to cfg.tapsmofrq = 0.4
ftcoherence(basename);

%%
calcgraph(basename);

%%
% Before running this step, change erange to [0 0.35] and vrange to [0 0.25]
% in plothead.m

plothead(basename, 3);