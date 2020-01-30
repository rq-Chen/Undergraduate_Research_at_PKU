%% Preprocessing.m - automatic preprocessing
%
% Ruiqi Chen, 11/26/2019
%
% <strong>Requirement: binica.m</strong>
%
% All data should be put in the directory DFPATH, which contains:
%
%   - a mat file entitled CHNREJFILE: contains a n*2 cell matrix chnRej, 
%       subject's full name (name+number) in column 1, rejected channels (a
%       cell vector of strings) in column 2. This file will be modified.
%
%   - several folders, named by the subjects' full name, containing .eeg
%
% <strong>Pipeline:</strong>
%
%   - load data
%   - auto select channel location
%   - add FCz as reference
%   - re-refernce to average of TP9/TP10 and insert FCz back
%   - 50Hz notched
%   - 0.3~50Hz filtered
%   - reject and interpolate pre-defined bad channels
%   - automatic channel rejection (exclude VEOG) and interpolate back
%   - merge and record the rejected and pre-defined bad channels
%   - epoch, -1~4s locked to all events
%   - ica by binica.m
%   - save data
%   - clear the files created by binica

clear;clc;close all;

%% parameters

DFPATH = '..\';
CHNREJFILE = 'chnRej.mat';
MODE = 'run';  % select MODE as 'debug' for debugging

%% Get folders

load([DFPATH CHNREJFILE], 'chnRej');

allDir = dir(DFPATH);
isFolder = [allDir.isdir];
Folders = {allDir.name};
Folders = Folders(isFolder);  % Caution: including .\ and ..\ too!

%% Processing

for i = 1:length(Folders)
    
    % skip ./ and ../
    if Folders{i}(1) == '.'
        continue;
    end
    currSub = Folders{i};
    
    % check whether the folder contains data
    allVhdr = dir([DFPATH currSub '/*.vhdr']);
    if length(allVhdr) ~= 1
        warning("Folder %s is skipped due to file missing.\n", currSub);
        continue;
    else
        vhdrName = allVhdr.name;   
        
        % for debugging only
        if strcmp(MODE, 'debug')
            if strcmp(currSub, 'xlj2') == 0
                continue;
            end
        end
        
    end
    
    % load data and select channel location
    eeglab;
    EEG = pop_loadbv([DFPATH currSub '/'], vhdrName);
    % set Ref as FCz
    EEG = pop_chanedit(EEG, 'lookup','Standard-10-5-Cap385.sfp',...
        'insert',65,'changefield',{65 'labels' 'FCz'},...
        'lookup','Standard-10-5-Cap385.sfp','setref',{'1:65' 'FCz'});
    EEG = eeg_checkset( EEG );
    
    % re-reference to average mastoid and bring back Ref (FCz)
    EEG = pop_reref( EEG, [31 32] ,'refloc',struct('labels',{'FCz'},...
        'type',{''},'theta',{0},'radius',{0.12662},'X',{0.0387},'Y',{0},...
        'Z',{0.0921},'sph_theta',{0},'sph_phi',{67.2081},...
        'sph_radius',{0.0999},'urchan',{65},'ref',{'FCz'},...
        'datachan',{0},'sph_theta_besa',{22.7919},'sph_phi_besa',{90}));
    EEG = eeg_checkset( EEG );
    
    % notched, 50Hz
    EEG = pop_eegfiltnew(EEG, 'locutoff',49,'hicutoff',51,'revfilt',1);
    EEG = eeg_checkset( EEG );
    
    % filter, 0.3-50Hz
    EEG = pop_eegfiltnew(EEG, 'locutoff',0.3,'hicutoff',50);
    EEG = eeg_checkset( EEG );

    % check whether bad channels are marked
    % reject and interpolate them
    badChannels = [];
    subRejNum = 0;
    oldChanlocs = EEG.chanlocs;
    chnLabel = {EEG.chanlocs.labels};
    for j = 1:size(chnRej, 1)
        if strcmp(chnRej{j, 1}, currSub)
            
            % register the bad channels
            subRejNum = j;
            for currChn = chnRej{j, 2}
                for currInd = 1:length(chnLabel)
                    if strcmp(currChn, chnLabel{currInd})
                        badChannels = [badChannels; currInd];
                        break
                    end
                end
            end
            
            % reject marked bad channels
            EEG = pop_select( EEG, 'nochannel',chnRej{j, 2});
            EEG = eeg_checkset( EEG );
            % and interpolate back (chnLabel will be maintained)
            EEG = pop_interp(EEG, oldChanlocs, 'spherical');
            EEG = eeg_checkset( EEG );
             
            break
        end
    end
    
    % automatic channel rejection (default setting)
    
    for currInd = 1:length(chnLabel)  % exclude VEOG
        if strcmp('VEOG', chnLabel{currInd})
            veogInd = currInd;
            if veogInd == 1
                elecRange = 2:length(chnLabel);
            elseif veogInd == length(chnLabel)
                elecRange = 1:length(chnLabel) - 1;
            else
                elecRange = [1:veogInd - 1 veogInd + 1:length(chnLabel)];
            end
            break
        end
    end
    
    % remove bad channels except VEOG
    [EEG, indelec] = pop_rejchan(EEG, 'elec', elecRange,...
        'threshold',5,'norm','on','measure','kurt');
    EEG = eeg_checkset( EEG );
    
    % interpolate the removed channels
    EEG = pop_interp(EEG, oldChanlocs, 'spherical');
    EEG = eeg_checkset( EEG );
    
    % record the rejected channels    
    indelec = elecRange(indelec);  % Important! Get correct indices.
    badChannels = union(badChannels, indelec)';  % column vector 
    if ~isempty(badChannels)
        badChnLabel = chnLabel(badChannels)';
        if subRejNum
            chnRej{subRejNum, 2} = badChnLabel;
        else
            chnRej = [chnRej; {currSub, badChnLabel}];
        end
    end
    
    % epoch, -1~4
    EEG = pop_epoch( EEG, {  }, [-1  4], 'newname', [currSub 'Epoch'],...
        'epochinfo', 'yes');
    EEG = eeg_checkset( EEG );
    
    % ica
    if strcmp(MODE, 'debug') == 0
        EEG = pop_runica(EEG, 'icatype', 'binica', 'extended',1);
        EEG = eeg_checkset( EEG );
    end
    
    % save data
    if strcmp(MODE, 'debug') == 0
        pop_newset(ALLEEG, EEG, 1,'savenew',...
            [DFPATH currSub '/' currSub 'Epoch.set'],'overwrite','on',...
            'gui','off');
    end
    
end

eeglab redraw;
if strcmp(MODE, 'debug') == 0
    save([DFPATH CHNREJFILE], 'chnRej');
    delete binica*.* % you may clear these files generated by binica
end