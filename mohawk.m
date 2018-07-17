function mohawk

mohawkpath = fileparts(mfilename('fullpath'));
loadpathsloc = sprintf('%s%sloadpaths.m',mohawkpath,filesep);

if exist(loadpathsloc,'file')
    run(loadpathsloc);
else
    filepath = userpath;
end

datatypes = {
    'RAW', '*.raw', 'EGI RAW file'
    'MFF_File', '*.mff', 'EGI MFF file'
    'MFF_Folder', '', 'EGI MFF folder'
    };

[datatype,ok] = listdlg2('PromptString','Select type of dataset to import:',...
    'SelectionMode','single','ListString',datatypes(:,3));

if ~ok
    return
end

if (strcmp(datatypes{datatype,1},'MFF_Folder') || strcmp(datatypes{datatype,1},'MFF_File')) && ...
        ~any(contains(javaclasspath('-all'),'MFF-1.2.jar'))
    mffjarfile = which('MFF-1.2.jar');
    if isempty(mffjarfile)
        error('MFF-1.2.jar not found.');
    end
    if ismac
        javaaddpath(mffjarfile);
    else
        if all(~contains(javaclasspath('-static'),mffjarfile))
            if isempty(userpath)
                userpath('reset');
            end
            userdir = strtok(userpath,pathsep);
            javaclasspathfile = sprintf('%s%sjavaclasspath.txt',userdir,filesep);
            fid = fopen(javaclasspathfile,'a');
            if fid == -1
                error('Could not open %s for writing.',javaclasspathfile);
            end
            
            fprintf(fid,'\n%s',mffjarfile);
            fclose(fid);
            
            fprintf('\nMOHAWK: added MFF jar file to static javaclasspath.\n');
            fprintf('MOHAWK: MATLAB needs to be restarted for changes to take effect.\n');
            fprintf('\nMOHAWK: press ENTER to exit and restart MATLAB.\n');
            pause;
            exit
        end
    end
end

fprintf('\n*** IMPORTING %s ***\n',datatypes{datatype,3});
if strcmp(datatypes{datatype,1},'MFF_Folder')
    filename = uigetdir(filepath);
    if isempty(filename)
        return
    end
    [filepath,filename] = fileparts(filename);
    filepath = [filepath filesep];
    filename = strtok(filename,'.');
else
    [filename,filepath] = uigetfile(datatypes{datatype,2},'MOHAWK - Select file to process',filepath);
    if filename == 0
        return
    end
    
    [filename,ext] = strtok(filename,'.');
    if ~any(strcmp(['*' ext],datatypes(1:end-1,2)))
        error('Unrecognised filetype: %s', ext);
    end
end

answers = inputdlg2({'Specify dataset base name:'},'MOHAWK Dataset',1,{filename});

if isempty(answers)
    return
elseif isempty(answers{1})
    error('Basename cannot be empty.');
else
    basename = answers{1};
end

fid = fopen(loadpathsloc,'w');
fprintf(fid,'filepath=''%s'';',filepath);
fclose(fid);

if ~exist(sprintf('%s%sfigures',filepath,filesep),'dir')
    mkdir(sprintf('%s%sfigures',filepath,filesep));
end

cur_wd = pwd;
cd(mohawkpath);

fprintf('\n*** IMPORTING DATA ***\n');
%% 
dataimport(filename,basename,datatypes{datatype,1});
%% 

fprintf('\n*** EPOCHING DATA ***\n');
epochdata(basename);

%% MANUAL
fprintf('\n*** SELECT BAD CHANNELS AND TRIALS ***\n');
rejartifacts([basename '_epochs'], 1, 4, 1);
%%

fprintf('\n*** COMPUTING IC DECOMPOSITION ***\n');
computeic([basename '_epochs'])

%% MANUAL
fprintf('\n*** SELECT BAD ICs ***\n');
rejectic(basename, 'prompt', 'off')

%% MANUAL
fprintf('\n*** SELECT ANY REMAINING BAD CHANNELS AND TRIALS AND INTERPOLATE ***\n');
rejartifacts([basename '_clean'], 2, 4, 0, [], 500, 250);
%%

fprintf('\n*** REFERENCING DATA TO COMMON AVERAGE ***\n');
rereference(basename, 1);

fprintf('\n*** RETAINING 10 MINUTES (60 EPOCHS) OF DATA ***\n');
checktrials(basename,60,'');

fprintf('\n*** CALCULATING MULTITAPER SPECTRUM ***\n');
calcftspec(basename);

fprintf('\n*** PLOTTING SPECTRUM ***\n');
plotftspec(basename);

fprintf('\n*** CALCULATING CONNECTIVITY ***\n');
ftcoherence(basename);

fprintf('\n*** CALCULATING GRAPH-THEORETIC NETWORK METRICS ***\n');
calcgraph(basename);

fprintf('\n*** PLOTTING MOHAWK ***\n');
plothead(basename,1);
plothead(basename,2);
plothead(basename,3);

fprintf('\n*** PLOTTING METRICS ***\n');
plotmetric(basename,'participation coefficient',3,'ylabel','Network centrality')
plotbands(basename,'participation coefficient','title','Network centrality');

fprintf('\n*** RUNNING CLASSIFIER ***\n');
testind(basename);
plotclass(basename);

fprintf('\n*** DONE! ***\n');

cd(cur_wd);