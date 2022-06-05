function mohawk

% Copyright (C) 2022 Srivas Chennu, University of Kent and University of Cambrige,
% srivas@gmail.com
% 
% 
% Invokes the MOHAWK pipeline to process hdEEG data collected with
% EGI systems. The pipeline estimates resting state brain connectivity, as
% measured by dwPLI[1], in canonical frequency bands. It then visualises
% in 3D topographs as shown in [2].
% 
% [1] Vinck M, Oostenveld R, van Wingerden M, Battaglia F, Pennartz CM.
% An improved index of phase-synchronization for electrophysiological data in
% the presence of volume-conduction, noise and sample-size bias.
% Neuroimage. 2011;55(4):1548-65.
% 
% [2] Chennu S, Annen J, Wannez S, Thibaut A, Chatelle C, Cassol H, et al.
% Brain networks predict metabolism, diagnosis and prognosis at the bedside
% in disorders of consciousness. Brain. 2017;140(8):2120-32.
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


fig_b = banner;
pause(3);
if ishandle(fig_b)
    close(fig_b);
end

mohawkpath = fileparts(mfilename('fullpath'));
loadpathsloc = sprintf('%s%sloadpaths.m',mohawkpath,filesep);

if exist(loadpathsloc,'file')
    run(loadpathsloc);
else
    filepath = userpath;
end

% Start by importing raw data in either RAW, MFF (Mac) file or MFF
% directory (Windows)

datatypes = {
    'RAW', '*.raw', 'EGI RAW file'
    'EDF', '*.edf', 'EDF file'
    'MFF_File', '*.mff', 'EGI MFF file'
    'VHDR', '*.vhdr', 'BrainProducts VHDR file'    
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
    if ~any(strcmp(['*' ext], datatypes(1:end-1,2)))
        error('Unrecognised filetype: %s', ext);
    end
end

% Specify a name for the final file
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

% Import the selected file into EEGLAB
fprintf('\n*** IMPORTING DATA ***\n');
%% 
dataimport(filename,basename,datatypes{datatype,1});
%% 

% Epoch data into 10 sec epochs
fprintf('\n*** EPOCHING DATA ***\n');
epochdata(basename);

%% MANUAL STEP
% First pass of quasi-automatic rejection of noisy channels and epochs based on variance
% thresholding
fprintf('\n*** SELECT BAD CHANNELS AND TRIALS ***\n');
rejartifacts([basename '_epochs'], 1, 4, 1);
%%

fprintf('\n*** COMPUTING IC DECOMPOSITION ***\n');
% Run ICA decomposition with optional PCA pre-processing
computeic([basename '_epochs'])

%% MANUAL
fprintf('\n*** SELECT BAD ICs ***\n');
% Visually identify and reject noisy ICs, e.g., eye movements, muscle
% activity, etc.
rejectic(basename, 'prompt', 'off')

%% MANUAL
% Second and final pass of quasi-automatic rejection of noisy channels and epochs based on variance
% thresholding, to remove any remaining noisy data.
fprintf('\n*** SELECT ANY REMAINING BAD CHANNELS AND TRIALS AND INTERPOLATE ***\n');
rejartifacts([basename '_clean'], 2, 4, 0, [], 500, 250);
%%

fprintf('\n*** REFERENCING DATA TO COMMON AVERAGE ***\n');
% re-reference data to common average for connectivity estimation.
rereference(basename, 1);

fprintf('\n*** RETAINING 10 MINUTES (60 EPOCHS) OF DATA ***\n');
% optionally fix number of epochs contributing to connectivity estimation.
% 60 epochs below will effectively use 10 minutes of clean data.
checktrials(basename,60,'');

fprintf('\n*** CALCULATING MULTITAPER SPECTRUM ***\n');
% calculate power spectrum using the multi-taper method
calcftspec(basename);

fprintf('\n*** PLOTTING SPECTRUM ***\n');
% visualise and save the power spectrum of all channels
plotftspec(basename);

fprintf('\n*** CALCULATING CONNECTIVITY ***\n');
% estimate dwPLI connectivity between pairs of channels
ftcoherence(basename);

fprintf('\n*** CALCULATING GRAPH-THEORETIC NETWORK METRICS ***\n');
% calculate graph theory metrics
calcgraph(basename);

fprintf('\n*** PLOTTING MOHAWK ***\n');
% plot 3D connectivity topographs in the delta, theta and alpha bands.
plothead(basename,1);
plothead(basename,2);
plothead(basename,3);

% The steps below require previously prepared group datasets
% fprintf('\n*** PLOTTING METRICS ***\n');
% plotmetric(basename,'participation coefficient',3,'ylabel','Network centrality')
% plotbands(basename,'participation coefficient','title','Network centrality');

% The steps below requires a previouly estimated classification ensemble.
% fprintf('\n*** RUNNING CLASSIFIER ***\n');
% testind(basename);
% plotclass(basename);

fprintf('\n*** DONE! ***\n');

cd(cur_wd);