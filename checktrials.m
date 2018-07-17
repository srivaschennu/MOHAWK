function trialcount = checktrials(basename,settrials,filesuffix)

loadpaths

EEG = pop_loadset('filepath',filepath,'filename',[basename filesuffix '.set'],'loadmode','info');

trialcount = EEG.trials;

if trialcount < settrials
    warning('Number of trials %d less than %d!',trialcount,settrials);
    return
end

fprintf('Found %d trials.\n',trialcount);

if trialcount > settrials
    EEG = pop_loadset('filepath',filepath,'filename',[basename filesuffix '.set']);
    trialvar = var(reshape(EEG.data,size(EEG.data,1)*size(EEG.data,2),size(EEG.data,3)));
    [~, deletetrials] = sort(trialvar,'descend');
    EEG = pop_select(EEG,'notrial',deletetrials(1:trialcount-settrials));
    EEG.saved = 'no';
    fprintf('Resaving to %s%s.\n',EEG.filepath,EEG.filename);
    pop_saveset(EEG,'savemode','resave');
end