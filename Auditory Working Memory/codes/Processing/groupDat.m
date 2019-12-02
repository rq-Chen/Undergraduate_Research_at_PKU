%% groupDat.m - Group the data by condition and response
%
% Ruiqi Chen, 11/21/2019
%
% Compatible with Brain Vision

clear;clc;close;


%% Parameters

DFPATH = '../';
SVPATH = '../../analysis/';
NBLOCKS = 8;
NTRIALS = 54;
latincondition = [1 3 2 4 2 1 4 3 1 3 2 4 2 1 4 3];
CONDITIONS = {'Simple', 'Reversed', 'Transposition', 'Contour'};


%% Get folders

allDir = dir(DFPATH);
isFolder = [allDir.isdir];
Folders = {allDir.name};
Folders = Folders(isFolder);  % Caution: including .\ and ..\ too!

%% Operation

for i = 1:length(Folders)
    if Folders{i}(1) == '.'
        continue;
    end
    currFolder = Folders{i};
    
    % check whether the folder contains data
    if length(dir([DFPATH currFolder '/' currFolder '.*'])) < 3  % set,fdt,mat
        warning("Folder %s is skipped due to file missing.\n", currFolder);
        continue;
    end
    
    % load mat and set data
    load([DFPATH currFolder '/' currFolder '.mat'], 'RT', 'Subinfo', ...
        'TrialType', 'ResponseType');
    
    % Originally these variables are all NBLOCKS * NTRIALS double matrices.
    %   Therefore, we need to transpose and then flatten them to get a
    %   vector, so that the order will be preserved.
    allHit = (TrialType == ResponseType)';
    allRT = RT';
    iBlock = mod(str2num(Subinfo{2}) - 1, 8) + 1;  % beginning block
    blockType = latincondition(iBlock : iBlock + NBLOCKS - 1);
    for j = 1:NBLOCKS  % change variable TrialType into condition label
        TrialType(j, :) = blockType(j);
    end
    TrialType = TrialType';  % transpose these matrices (then flatten)
    
    load([DFPATH currFolder '/' currFolder '.set'], 'EEG', '-mat');
    epochInd = [EEG.epoch.eventbvmknum] - 1;  % range: 1 to 432
    allHit = allHit(epochInd);  % change into a vector and select data
    allRT = allRT(epochInd);
    TrialType = TrialType(epochInd);
    
    % load EEG data
    eeglab;
    EEG = pop_loadset([DFPATH currFolder '/' currFolder '.set']);
    allData = EEG.data;
    
    % grouping
    for cond = 1:length(CONDITIONS)
        
        % get data first
        blockHit = allHit(TrialType == cond);
        blockRT = allRT(TrialType == cond);
        blockData = allData(:,:,TrialType == cond); % channel*time*trial
        
        % correct trials
        RT = blockRT(blockHit);
        eegdata = blockData(:,:,blockHit);
        fileName = [currFolder CONDITIONS{cond} 'T.mat'];
        mkdir([SVPATH currFolder '/']);
        save([SVPATH currFolder '/' fileName], 'RT', 'eegdata');
        
        % incorrect trials
        RT = blockRT(~blockHit);
        eegdata = blockData(:,:,~blockHit);
        fileName = [currFolder CONDITIONS{cond} 'F.mat'];
        mkdir([SVPATH currFolder '/']);
        save([SVPATH currFolder '/' fileName], 'RT', 'eegdata');        
        
    end
    
end

close all;