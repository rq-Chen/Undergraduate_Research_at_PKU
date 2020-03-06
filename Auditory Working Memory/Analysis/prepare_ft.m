%% prepare_ft - Average, Baseline Correction & Convert to fieldtrip
%
% Ruiqi Chen, 01/31/2020
%
% Requirement: mat2ft.m


clear;clc;close all;


%% Parameters

DFPATH = '../';
CHNPATH = '../../';
SAVEPATH = '../group/';
TORF = 'T';

% further processing, set as 'ERP', 'TF' or 'Trials'
DATATYPE = 'TF';

% parameters for baseline correction
BASELINE = [-1 0];  % in seconds

% parameters for wavelet transform
FTFOI = 2:30;
FTTOI = -1:0.01:4;
FTWIDTH = 7;
FTBASECORR = 'zscore';

CONDITIONS = {'Simple', 'Reversed', 'Transposition', 'Contour'};


%% Get folders

allDir = dir(DFPATH);
isFolder = [allDir.isdir];
Folders = {allDir.name};
Folders = Folders(isFolder);
Folders = Folders(3:end);  % skip .\ and ..\


%% Set configuration

cfg = struct();
cfg.baseline = BASELINE;
if strcmp(DATATYPE, 'ERP')
    cfg.parameter = 'trial';    
elseif strcmp(DATATYPE, 'TF')
    cfg.method = 'tfr';
    cfg.output = 'pow';
    cfg.foi = FTFOI;
    cfg.toi = FTTOI;
    cfg.width = FTWIDTH;
    cfg.baselinetype = FTBASECORR;
end


%% Restore data

for cond = 1:length(CONDITIONS)
    
    allSub = {};
    allDat = {};
    
    for currFold = Folders
        
        currSub = currFold{1};
        DATFILE = [DFPATH currSub '/' currSub CONDITIONS{cond} TORF '.mat'];
        CHNFILE = [CHNPATH currSub '/' currSub '.set'];
        if size(dir(DATFILE), 1) == 0
            warning("File missing. Folder %s is skipped.\n", currSub);
            continue;
        end
                
        load(DATFILE, 'eegdata');
        if size(eegdata, 3) < 5
            warning("Too few trials. Folder %s is skipped.\n", currSub);
            continue;
        end
        
        allSub = [allSub currSub];
        timelock = mat2ft(eegdata, 'eegfile', CHNFILE);
        
        if strcmp(DATATYPE, 'ERP')
            % an ugly method, but if we switched the order of these two
            %   steps, no baseline correction will be done
            timelock = ft_timelockbaseline(cfg, timelock);
            timelock = ft_timelockanalysis(struct(), timelock);
        elseif strcmp(DATATYPE, 'TF')
            timelock = ft_freqanalysis(cfg, timelock);
            timelock = ft_freqbaseline(cfg, timelock);
        end
        
        allDat = [allDat timelock];

    end
    mkdir(SAVEPATH);
    if strcmp(DATATYPE, 'ERP')
        save([SAVEPATH CONDITIONS{cond} TORF '_ERP.mat'], 'allSub', 'allDat');
    elseif strcmp(DATATYPE, 'TF')
        save([SAVEPATH CONDITIONS{cond} TORF '_TF.mat'], 'allSub', 'allDat');
    else
        save([SAVEPATH CONDITIONS{cond} TORF '.mat'], 'allSub', 'allDat');
    end
end