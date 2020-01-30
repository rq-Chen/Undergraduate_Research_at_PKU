%% ERPAnalysis.m - Compute ERP and Illustrate
%
% Ruiqi Chen, 12/11/2019
%
% Compute the ERP for correct trials only and compare across conditions.
%
% Baseline: -0.2~0s.

clear;clc;close all;


%% Parameters

DFPATH = '../';
CHNFILE = '../chanlocs.mat';
ROI = '';  % Draw picture for this channel
MINTRIALNUM = 5;
fs = 500;
nTime = 2500;
nSub = 11;
BSLTIME = 0.2;
SINGLESUB = '';  % specify it as '' for averaging across subjects


% conditions name, the first one will be subtracted from others
CONDITIONS = {'Simple', 'Reversed', 'Transposition', 'Contour'};


%% Get folders

allDir = dir(DFPATH);
isFolder = [allDir.isdir];
Folders = {allDir.name};
Folders = Folders(isFolder);
Folders = Folders(3:end);  % skip .\ and ..\


%% Computation

% Get channel index
load(CHNFILE, 'chanlocs');
nChan = size(chanlocs, 2);
nCond = length(CONDITIONS);
allTime = (0:nTime - 1) / fs - 1;

allERP = nan(nCond, nSub, nChan, nTime);
% dim 2 may have some redundancy

for cond = 1:nCond
    
    cntSub = 0;
    for currFold = Folders
        
        currSub = currFold{1};
        DATFILE = [DFPATH currSub '/' currSub CONDITIONS{cond} 'T.mat'];
        if size(dir(DATFILE), 1) == 0
            warning("File missing. Folder %s is skipped.\n", currSub);
            continue;
        end
        
        if ~isempty(SINGLESUB)
            if strcmp(SINGLESUB, currSub) == 0
                continue;
            end
        end
        
        load(DATFILE, 'eegdata');
        if size(eegdata, 3) < MINTRIALNUM
            warning("Not enough trials. Folder %s is skipped.\n", currSub);
            continue;
        end        
        
        cntSub = cntSub + 1;
        eegdata = double(eegdata);
        nTrials = size(eegdata, 3);
        
        % average and remove baseline
        tmp = squeeze(mean(eegdata, 3));
        tmp = tmp - mean(tmp(:, (fs*(1 - BSLTIME)):fs), 2);
        allERP(cond, cntSub, :, :) = tmp;
        
    end
end
save([DFPATH 'allTERP.mat'], 'allERP');


%% Illustration

if isempty(ROI)
    return;
end

ROIIND = 0;
for i = 1:nChan
    if strcmp(chanlocs(i).labels, ROI)
        ROIIND = i;
        break
    end
end
if ROIIND == 0
    error("%s is not a valid channel label!\n", ROI);
end

meanERP = zeros(nCond, nTime);
semERP = zeros(nCond, nTime);
for cond = 1:nCond
    meanERP(cond,:) = ...
        squeeze(mean(allERP(cond, :, ROIIND, :), 2));
    semERP(cond,:) = ...
        squeeze(std(allERP(cond, :, ROIIND, :), 0, 2)) /...
            sqrt(nSub);
end

for cond = 2:nCond
    figure; hold on;
    title([ROI ...
        sprintf(' ERP for %s and %s', CONDITIONS{1}, CONDITIONS{cond})]);
    plot(allTime, meanERP(1,:), '-b');
    plot(allTime, meanERP(cond,:), '-r');
    fill([allTime allTime(end:-1:1)], ...
        [meanERP(1, :) + semERP(1, :) ...
        meanERP(1,end:-1:1)- semERP(1,end:-1:1)],...
        'b','EdgeColor','none','FaceAlpha',0.2);
    fill([allTime allTime(end:-1:1)], ...
        [meanERP(cond, :) + semERP(cond, :) ...
        meanERP(cond, end:-1:1)- semERP(cond,end:-1:1)],...
        'r','EdgeColor','none','FaceAlpha',0.2);
    legend(CONDITIONS([1 cond]));
end