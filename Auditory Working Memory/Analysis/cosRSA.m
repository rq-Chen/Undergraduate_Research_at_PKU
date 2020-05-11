%% rsaReversed.m - RSA on the REVERSED condition
%
% Ruiqi Chen, 04/16/2020
%

clear;clc;close all;


%% Parameters

DFPATH = '../';
STIFILE = 'StiNotes.mat';
fs = 500;
BIN = 50;  % in ms
timePoint = -4:0.002:5.998;
CONDITIONS = {'Simple', 'Reversed', 'Transposition', 'Contour'};
CONDOI = 'Contour';

% Debugging
MODE = 'debug';

% Distance function
disFun = @cosVal;

% For illustration
cLim = [0 0.1];
OUTPUTFILE = 'cosRSM.gif';
FPS = 4;
timeInt = 1 / FPS;


%% Preparation

nCond = length(CONDITIONS);
load([DFPATH STIFILE], 'StiNotes', 'NOTES');
allS1 = reshape(squeeze(StiNotes(1,:,:,1:3)), [], 3);
% (All conditions use the same 108 S1)

binPoint = floor(BIN / (1000 / fs));


%% Get folders

allDir = dir(DFPATH);
isFolder = [allDir.isdir];
Folders = {allDir.name};
Folders = Folders(isFolder);
Folders = Folders(3:end);  % skip .\ and ..\


%% Compute RDM

nSub = 0;
binN = ceil(length(timePoint) / binPoint);
allNeuRDM = zeros(4, 4, binN);
for currFold = Folders
    
    % Load data
    
    currSub = currFold{1};
    if isempty(dir([DFPATH currSub '/' currSub CONDOI 'T.mat']))
        warning("File missing. Folder %s is skipped.\n", currSub);
        continue;
    end
    
    % debugging
    if strcmp(MODE, 'debug')
        if ~strcmp('wjm3', currSub)
            continue
        end
    end
    
    nSub = nSub + 1;
    allNotes = cell(1, nCond);
    allData = cell(1, nCond);
    for i = 1:nCond
        currFile = [DFPATH currSub '/' currSub CONDITIONS{i} 'T.mat'];
        load(currFile, 'Notes', 'eegdata');
        allNotes{i} = Notes;
        allData{i} = eegdata;
    end
    otherNotes = cat(1, allNotes{strcmp(CONDITIONS, CONDOI)});
    otherData = cat(3, allData{strcmp(CONDITIONS, CONDOI)});
    revNotes = allNotes{strcmp(CONDITIONS, CONDOI)};
    revData = allData{strcmp(CONDITIONS, CONDOI)};
    
    clear allNotes allData
    
    % Categorize each trial
    
    contType = [1 1; 1 -1; -1 1; -1 -1];
    revSign = sign(revNotes(:, 2:3) - revNotes(:, 1:2));
    revType = zeros(size(revNotes, 1), 1);
    for i = 1:length(revType)
        for j = 1:4
            if isequal(revSign(i,:), contType(j,:))
                revType(i) = j;
                break
            end
        end
    end
    otherSign = sign(otherNotes(:, 2:3) - otherNotes(:, 1:2));
    otherType = zeros(size(otherNotes, 1), 1);
    for i = 1:length(otherType)
        for j = 1:4
            if isequal(otherSign(i,:), contType(j,:))
                otherType(i) = j;
                break
            end
        end
    end
    
    % Calculate representation dissimilarity
    
    neuRDM = nan(4, 4, size(revData, 2));
    for i = 1:4
        revTrials = revData(:, :, revType == i);
        revN = size(revTrials, 3);
        for j = 1:4
            otherTrials = otherData(:, :, otherType == j);
            otherN = size(otherTrials, 3);
            tmp = zeros(1, size(revData, 2));
            for k = 1:revN
                for l = 1:otherN
                    if i == j && k == l  % Skip identical trial
                        continue
                    end
                    tmp = tmp + ...
                        disFun(revTrials(:,:,k), otherTrials(:,:,l), 1);
                end
            end
            if i == j
                neuRDM(i, j, :) = tmp / (revN * otherN - revN);
            else
                neuRDM(i, j, :) = tmp / (revN * otherN);
            end
        end
    end
    tmp = zeros(4, 4, binN);
    for i = 1:binN
        lastI = min(size(neuRDM, 3), i * binPoint);
        tmp(:, :, i) = mean(neuRDM(:, :, (i - 1) * binPoint + 1 : lastI), 3);
    end
    neuRDM = tmp;
    allNeuRDM = allNeuRDM + neuRDM;
    
end


%% Illustration

neuRDM = allNeuRDM / nSub;

if ~isempty(dir(OUTPUTFILE))
    delete(OUTPUTFILE);
end
fig = figure;
fig.Colormap = hot;
for i = 95:135
    
    imagesc(neuRDM(:,:,i));
    xticks(1:4); xticklabels({'++', '+-', '-+', '--'});
    yticks(1:4); yticklabels({'++', '+-', '-+', '--'});
    caxis(cLim); colorbar;
    lastI = min(length(timePoint), i * binPoint);
    title(sprintf('Neural RDM from %.3f to %.3f', ...
        timePoint((i - 1) * binPoint + 1), timePoint(lastI)));
    
    imgTmp = frame2im(getframe(fig));
    [A,map] = rgb2ind(imgTmp,256);

    if isempty(dir(OUTPUTFILE))
        imwrite(A,map,OUTPUTFILE,'gif','LoopCount',Inf,...
            'DelayTime', timeInt);
    else
        imwrite(A,map,OUTPUTFILE,'gif','WriteMode','append',...
            'DelayTime', timeInt);
    end
end
close;


%% Distance function
function dis = euclidDis(a, b, d)
    if nargin < 3
        d = find(size(a) > 1, 1);
        if isempty(d)
            d = 1;
        end
    end
    dis = sqrt(sum((a - b) .^ 2, d));
end