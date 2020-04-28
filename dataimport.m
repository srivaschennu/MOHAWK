function dataimport(filename,basename,datatype)

% Copyright (C) 2018 Srivas Chennu, University of Kent and University of Cambrige,
% srivas@gmail.com
% 
% 
% Import data into EEGLAB format and perform basic pre-processing.
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
do_high_pass = true;
switch datatype
    case {'RAW','EGI_binary'}
        fullfile = [filepath filename '.raw'];
        if ~exist(fullfile,'file')
            fullfile = [filepath filename];
        end
        EEG = pop_readegi(fullfile, [],[],[]);
        switch EEG.nbchan
            case 32
                chanlocfile = 'GSN-HydroCel-33-Fidu.sfp';
            case 64
                chanlocfile = 'GSN-HydroCel-65-Fidu.sfp';
            case 128
                chanlocfile = 'GSN-HydroCel-129-Fidu.sfp';
            case 256
                chanlocfile = 'GSN-HydroCel-257-Fidu.sfp';
            case 8
                chanlocfile = 'PIB.sfp';
        end
        chanlocfile = which(chanlocfile);
        EEG = fixegilocs(EEG,chanlocfile);
    case {'MFF_File','MFF_Folder'}
        fullfile = [filepath filename '.mff'];
        if ~exist(fullfile,'file')
            fullfile = [filepath filename];
        end
        EEG = pop_readegimff(fullfile);
%     case 'EGI_binary' % for resting sedation data
%         fullfile = [filepath filename];        
%         EEG = pop_readegi(fullfile, [],[],'auto');
    case 'BrainVision'        
        if ~contains(filename,'.')
            filename = [filename '.vhdr'];
        end
        EEG = pop_loadbv(filepath, filename);
        % add an empty CPz channel as this is the reference
        EEG = pop_chanedit(EEG, 'append',1,'changefield',{2 'labels' 'CPz'},'setref',{'1:128' 'CPz'});
        % lookup channel locs - assumes named in 10-5 system
        EEG = pop_chanedit(EEG, 'lookup', ['standard-10-5-cap385.elp']); 
    case 'EEGLAB'
        EEG = pop_loadset([filename '.set'], filepath);
        do_high_pass = false; % because LPAT acute data has already been high-pass filtered        
    otherwise
        error('Unsupported filetype %s.',datatype);
end

EEG = eeg_checkset(EEG);

%%%% PREPROCESSING

%REMOVE PERIPHERAL CHANNELS
switch datatype
    case {'RAW','MFF_File','MFF_Folder','EGI_binary'}
        if EEG.nbchan == 128
            chanexcl = {'E1', 'E8', 'E14', 'E17', 'E21', 'E25', 'E32', 'E38', 'E43', 'E44', 'E48', 'E49', 'E56', 'E57', 'E63', 'E64', 'E68', 'E69', 'E73', 'E74', 'E81', 'E82', 'E88', 'E89', 'E94', 'E95', 'E99', 'E100', 'E107', 'E113', 'E114', 'E119', 'E120', 'E121', 'E125', 'E126', 'E127', 'E128'};
        elseif EEG.nbchan == 256
            chanexcl = {'E31', 'E67', 'E73', 'E82', 'E91', 'E92', 'E93', 'E94', 'E102', 'E103', 'E104', 'E105', 'E111', 'E112', 'E113', 'E114', 'E120', 'E121', 'E122', 'E123', 'E133', 'E134', 'E135', 'E136', 'E145', 'E146', 'E147', 'E148', 'E156', 'E157', 'E158', 'E165', 'E166', 'E167', 'E168', 'E174', 'E175', 'E176', 'E177', 'E187', 'E188', 'E189', 'E190', 'E199', 'E200', 'E201', 'E208', 'E209', 'E216', 'E217', 'E218', 'E219', 'E225', 'E226', 'E227', 'E228', 'E229', 'E230', 'E231', 'E232', 'E233', 'E234', 'E235', 'E236', 'E237', 'E238', 'E239', 'E240', 'E241', 'E242', 'E243', 'E244', 'E245', 'E246', 'E247', 'E248', 'E249', 'E250', 'E251', 'E252', 'E253', 'E254', 'E255', 'E256'};
        else
            error('Invalid number of chanels found in data: %d.', EEG.nbchan);
        end
        
        %ask about 10-20
        chan_subset = questdlg('Do you want to select only the 10-20 channels?','10-20?','Yes','No','No');
        switch chan_subset            
            case 'Yes'         
            % 10-20 from EGI 129
            chaninc = {'E22' 'E9' 'E33' 'E24' 'E11' 'E124' 'E122' 'E45' 'E36' 'E104' 'E108' 'E58' 'E52' 'E62' 'E92' 'E96' 'E70' 'E83'};
            EEG = pop_select(EEG,'channel',chaninc);        
        end
        
    case 'BrainVision'
        chanexcl = {'HEOGR','HEOGL','VEOGU','VEOGL','M1','M2','BIP1','BIP2'};
        
        %% ONLY FOR TESTING 10-20 !!!
        chan_subset = questdlg('Do you want to select only the 10-20 channels?','10-20?','Yes','No','No');
        switch chan_subset            
            case 'Yes'
                % NB for some systems (i.e. ANT), T3=T7, T4=T8, T5=P7,
                % T6=P8. Our files are based on the T3 version so here we
                % change them to match
                new_ch_name = {'T3','T4','T5','T6'};
                old_ch_name = {'T7','T8','P7','P8'};
                
                for ch_name_idx = 1:length(old_ch_name)
                    chanidx = find(strcmp(old_ch_name(ch_name_idx),{EEG.chanlocs.labels}));
                    if ~isempty(chanidx)
                        EEG.chanlocs(chanidx).labels = new_ch_name{ch_name_idx};
                    end                    
                end
                
                chaninc = {'Fp1','Fp2','F7','F3','Fz','F4','F8','T3','C3','Cz','C4','T4','T5','P3','Pz','P4','T6','O1','O2'};
                EEG = pop_select(EEG,'channel',chaninc);        
        end
    case 'EEGLAB'
        chanexcl = {'ECG', 'A1', 'A2'};        
        
end

EEG = pop_select(EEG,'nochannel',chanexcl);

%REDUCE SAMPLING RATE TO 250HZ
if EEG.srate > 250
    fprintf('Downsampling to 250Hz.\n');
    EEG = pop_resample(EEG,250);
elseif EEG.srate < 250
    error('Sampling rate too low!');
end

%Filter
hpfreq = 0.5;
lpfreq = 45;
fprintf('Low-pass filtering below %.1fHz...\n',lpfreq);
EEG = pop_eegfiltnew(EEG, 0, lpfreq);

if do_high_pass
    fprintf('High-pass filtering above %.1fHz...\n',hpfreq);
    EEG = pop_eegfiltnew(EEG, hpfreq, 0);
end

%Remove line noise. Change line noise frequency below if needed.
fprintf('Removing line noise.\n');
EEG = rmlinenoisemt(EEG, 50);

EEG.setname = sprintf('%s_orig',basename);
EEG.filename = sprintf('%s_orig.set',basename);
EEG.filepath = filepath;

EEG = eeg_checkset(EEG);

fprintf('Saving %s%s.\n', EEG.filepath, EEG.filename);
pop_saveset(EEG,'filename', EEG.filename, 'filepath', EEG.filepath);
