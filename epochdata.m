function epochdata(basename)

loadpaths

EEG = pop_loadset('filepath',filepath,'filename',[basename '_orig.set']);

% Length of each epoch in seconds
epochlength = 10;

events = (0:epochlength:EEG.xmax)';
events = cat(2,repmat({'EVNT'},length(events),1),num2cell(events));
assignin('base','events',events);

EEG = pop_importevent(EEG,'event',events,'fields',{'type','latency'});
evalin('base','clear events');
EEG = eeg_checkset(EEG,'makeur');
EEG = eeg_checkset(EEG,'eventconsistency');

fprintf('\nSegmenting into %d sec epochs.\n',epochlength);
EEG = pop_epoch(EEG,{'EVNT'},[0 epochlength]);

EEG = pop_rmbase(EEG,[]);

EEG = eeg_checkset(EEG);

EEG.setname = [basename '_epochs'];
EEG.filename = [basename '_epochs.set'];
fprintf('Saving %s%s.\n',EEG.filepath,EEG.filename);
pop_saveset(EEG,'filename', EEG.filename, 'filepath', filepath);

end