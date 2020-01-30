%% wtAnalysis.m - Time-frequency analysis
%
% Ruiqi Chen, 12/11/2019
%
% Compute the Event-Related Spectral Perturbation (ERSP) for some ROI using
%   Gabor wavelets and compare them across conditions.
%
% The ERSP is computed by zscoring the power of the delay period
%   activity of each frequency band over its -1~0s baseline.

clear;clc;close all;


%% Parameters

DFPATH = '../';
CHNFILE = '../chanlocs.mat';
ROI = 'PO3';
SINGLESUB = '';  % specify it as '' for averaging across subjects
MINTRIALNUM = 5;
fs = 500;
nTime = 2500;
fLim = [2 50];


% conditions name, the first one will be subtracted from others
CONDITIONS = {'Simple', 'Reversed', 'Transposition', 'Contour'};


%% Get folders

allDir = dir(DFPATH);
isFolder = [allDir.isdir];
Folders = {allDir.name};
Folders = Folders(isFolder);
Folders = Folders(3:end);  % skip .\ and ..\


%% Computation

nCond = length(CONDITIONS);
nSub = zeros(1, nCond);
allTime = (0:nTime - 1) / fs - 1;

% Get channel index
load(CHNFILE, 'chanlocs');
ROIIND = 0;
for i = 1:size(chanlocs, 2)
    if strcmp(chanlocs(i).labels, ROI)
        ROIIND = i;
        break
    end
end
if ROIIND == 0
    error("%s is not a valid channel label!\n", ROI);
end

% pre-compute the filter to speed up the transformation
gaborFilt = cwtfilterbank('SignalLength', nTime, 'Wavelet','amor',...
    'SamplingFrequency', fs, 'FrequencyLimits', fLim);
allFreq = centerFrequencies(gaborFilt);
nScales = length(allFreq);

ERSP = zeros(nCond, nScales, nTime);
for cond = 1:nCond
    
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
        
        nSub(cond) = nSub(cond) + 1;        
        eegdata = double(eegdata);
        nTrials = size(eegdata, 3);
        allDecom = zeros(nTrials, nScales, nTime);
        for i = 1:nTrials
            [allDecom(i,:,:), ~, coi] = wt(gaborFilt, eegdata(ROIIND,:,i));
        end
        % change into energy
        allDecom = abs(allDecom) .^ 2;
        % compute the mu and sigma of the baseline power across trials
        [~, mu, sigma] = zscore(mean(allDecom(:, :, 1:fs),3), 0, 1);
        allDecom = (mean(allDecom) - mu) ./ sigma;
        
        % Sum the data from all subjects first
        ERSP(cond,:,:) = ERSP(cond,:,:) + allDecom;
    end
    % Then average
    ERSP(cond,:,:) = ERSP(cond,:,:) / nSub(cond);
end

%% Illustration

for cond = 2:nCond
    figure;
    pcolor(allTime, allFreq, squeeze(ERSP(cond,:,:) - ERSP(1,:,:)));
    shading flat
    hold on
    plot(allTime, coi, 'w-' ,'LineWidth',3)
    xlabel('Time (Seconds)')
    ylabel('Frequency (Hz)')
    title([CONDITIONS{cond} ' versus ' CONDITIONS{1}...
        ' Scalogram for ' ROI]);
    if ~isempty(SINGLESUB)
        caxis([-1 1]);
    else
        caxis([-0.3 0.3]);
    end
    colorbar;
    
end