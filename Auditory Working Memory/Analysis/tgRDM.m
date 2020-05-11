%% tgRDM.m - temporal-generalized RDM on one condition
%
% Ruiqi Chen, 05/08/2020
%

clear;clc;close all;


%% Parameters

DFPATH = '../';
STIFILE = 'StiNotes.mat';
TRAINFILE = 'trainDat.mat';
fs = 500;
BIN = 20;  % in ms
timePoint = -4:0.002:5.998;
TOI = [0.75 2.75];
CONDITIONS = {'Simple', 'Reversed', 'Transposition', 'Contour'};
contType = [1 1; 1 -1; -1 1; -1 -1];

% Debugging
MODE = 'run';  % Set as 'debug' for debugging

% Training data
CONDTRAIN = 'Reversed';
CONDTEST = 'Reversed';
trainRat = 0.05;  % Use only this proportion of time bin to train
BEGINOREND = 'end';  % Use the data at the beginning or end
nBinSkip = 0;  % Skip this number of bins at the selected end

% For LSTM
dropRat = 0.5;
nLSTMin = 8;
nHidU = 16;

% For training
valR = 0.2;
nEpochs = 50;
nBatchSize = 20;
LR = 1e-3;
lrDropFreq = 40;
lrDropRat = 0.2;

% For illustration
cLim = [0 0.5];
OUTPUTFILE = 'tmp.gif';
FPS = 4;
timeInt = 1 / FPS;


%% Preparation

nCond = length(CONDITIONS);
load([DFPATH STIFILE], 'StiNotes', 'NOTES');
allS1 = reshape(squeeze(StiNotes(1,:,:,1:3)), [], 3);
% (All conditions use the same 108 S1)

binPoint = floor(BIN / (1000 / fs));
indRange = and(timePoint >= TOI(1), timePoint < TOI(2));
binN = floor(sum(indRange) / binPoint);
trainN = floor(binN * trainRat);

% load(RNNFILE, 'Layers');
Layers = [ ...
    sequenceInputLayer(64)
    fullyConnectedLayer(nLSTMin)
    dropoutLayer(dropRat)
    lstmLayer(nHidU,'OutputMode','last')
    fullyConnectedLayer(4)
    softmaxLayer
    classificationLayer];


%% Get folders

allDir = dir(DFPATH);
isFolder = [allDir.isdir];
Folders = {allDir.name};
Folders = Folders(isFolder);
Folders = Folders(3:end);  % skip .\ and ..\


%% Compute RSM

nSub = 0;
allNeuRSM = {};
for currFold = Folders
    
    % Load data
    
    currSub = currFold{1};
    if isempty(dir([DFPATH currSub '/' currSub CONDTRAIN 'T.mat']))
        warning("File missing. Folder %s is skipped.\n", currSub);
        continue;
    end
    
    % debugging
    if strcmp(MODE, 'debug')
        if ~strcmp('wjm3', currSub)
            continue
        end
    end
    
    if 1 % isempty(dir([DFPATH currSub '/' TRAINFILE]))
        
        fprintf('Gathering data for %s ...\n', currSub);
        nSub = nSub + 1;
        allNotes = cell(1, nCond);
        allData = cell(1, nCond);
        for i = 1:nCond
            currFile = [DFPATH currSub '/' currSub CONDITIONS{i} 'T.mat'];
            load(currFile, 'Notes', 'eegdata');
            allNotes{i} = Notes;
            allData{i} = eegdata;
        end
        otherNotes = cat(1, allNotes{strcmp(CONDITIONS, CONDTRAIN)});
        otherData = cat(3, allData{strcmp(CONDITIONS, CONDTRAIN)});
        revNotes = allNotes{strcmp(CONDITIONS, CONDTEST)};
        revData = allData{strcmp(CONDITIONS, CONDTEST)};
        
        clear allNotes allData
        
        % Categorize each trial
        
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
        
        % slice data
        
        revData = revData(:, indRange, :);
        otherData = otherData(:, indRange, :);
        trainX = cell(size(otherData, 3), trainN);
        for i = 1:size(trainX, 1)
            for j = 1:size(trainX, 2)
                if strcmp(BEGINOREND, 'begin')
                    tmpJ = j + nBinSkip;
                    trainX{i, j} = squeeze(otherData(:, ...
                        (tmpJ - 1) * binPoint + 1 : tmpJ * binPoint, i));
                else
                    tmpJ = binN + 1 - nBinSkip - j;
                    trainX{i, j} = squeeze(otherData(:, ...
                        (tmpJ - 1) * binPoint + 1 : tmpJ * binPoint, i));
                end
            end
        end
        testX = cell(size(revData, 3), binN);
        for i = 1:size(testX, 1)
            for j = 1:size(testX, 2)
                testX{i, j} = squeeze(revData(:, ...
                    (j - 1) * binPoint + 1 : j * binPoint, i));
            end
        end
        trainY = categorical(repmat(otherType, 1, trainN));
        testY = categorical(repmat(revType, 1, binN));
        trainX = trainX(:); trainY = trainY(:);
        testX = testX(:); testY = testY(:);
        
        % save data
        
        save([DFPATH currSub '/' TRAINFILE], ...
            'trainX', 'trainY', 'testX', 'testY');
    else
        % load data
        fprintf('Loading data for %s ...\n', currSub);
        load([DFPATH currSub '/' TRAINFILE], ...
            'trainX', 'trainY', 'testX', 'testY');
    end
    
    % preprocess data
    
    nTmp = length(trainY);
    perm = randperm(nTmp);
    valX = trainX(perm(1: floor(valR * nTmp)));
    valY = trainY(perm(1: floor(valR * nTmp)));
    trainX = trainX(perm(floor(valR * nTmp) + 1 : end));
    trainY = trainY(perm(floor(valR * nTmp) + 1 : end));
    
    % set training options
    
    lstmOpt = trainingOptions('adam', ...
        'ExecutionEnvironment','cpu', ...
        'ValidationData', {valX, valY}, ...
        'ValidationFrequency', floor(length(trainY) / nBatchSize), ...
        'MaxEpochs', nEpochs, ...
        'MiniBatchSize', nBatchSize, ...
        'InitialLearnRate', LR, ...
        'LearnRateSchedule', 'piecewise', ...
        'LearnRateDropFactor', lrDropRat, ...
        'LearnRateDropPeriod', lrDropFreq, ...
        'Plots','training-progress');
    lstmModel = trainNetwork(trainX, trainY, Layers, lstmOpt);
    predP = predict(lstmModel, testX, 'ExecutionEnvironment', 'cpu');
%     [~, predY] = max(predP, 2);
    predP = reshape(predP, [], binN, 4);
%     acc = reshape(predY == testY, [], binN);
%     bcc = reshape(double(predY) == 5-double(testY), [], binN);  % post-
%     plot(mean(acc)); hold on; plot(mean(bcc));
%     legend({'Pre-transformed', 'Post-transformed'});
%     title('Decoding performance');

    % Calculate representation dissimilarity
    
    neuRSM = nan(4, 4, binN);  % rows: S1 category; columns: predicted
    revLabel = reshape(testY, [], binN);
    revLabel = double(revLabel(:, 1));
    for i = 1:4
        neuRSM(i, :, :) = permute(mean(predP(revLabel == i, :, :)), ...
            [1, 3, 2]);
    end
    allNeuRSM = [allNeuRSM neuRSM];
    
end


%% Illustration

% neuRSM = squeeze(mean(cat(4, allNeuRSM{:}), 4));
% fig = figure;
% % fig.Colormap = hot;
% timePoint = timePoint(timePoint >= 0);
% for i = 1:size(neuRSM, 3)
%     
%     imagesc(neuRSM(:,:,i));
%     xticks(1:4); xticklabels({'++', '+-', '-+', '--'});
%     yticks(1:4); yticklabels({'++', '+-', '-+', '--'});
%     caxis(cLim); colorbar;
%     lastI = min(length(timePoint), i * binPoint);
%     title(sprintf('Neural RDM from %.3f to %.3f', ...
%         timePoint((i - 1) * binPoint + 1), timePoint(lastI)));
%     
%     imgTmp = frame2im(getframe(fig));
%     [A,map] = rgb2ind(imgTmp,256);
%     
%     if i == 1
%         imwrite(A,map,OUTPUTFILE,'gif','LoopCount',Inf,...
%             'DelayTime', timeInt);
%     else
%         imwrite(A,map,OUTPUTFILE,'gif','WriteMode','append',...
%             'DelayTime', timeInt);
%     end
% end
% close;

% Plot decoding accuracy
if strcmp(BEGINOREND, 'begin')
    nBegin = nBinSkip + 1;
    nEnd = nBinSkip + trainN;
else
    nBegin = binN - nBinSkip - (trainN - 1);
    nEnd = binN - nBinSkip;
end
dBegin = (nBegin - 1) * BIN / 1000;
dEnd = nEnd * BIN / 1000;
tmp = cat(4, allNeuRSM{:});
acc = zeros(size(tmp, 3), size(tmp, 4));
bcc = acc;
for i = 1:4
    acc = acc + squeeze(tmp(i, i, :, :)) / 4;
    bcc = bcc + squeeze(tmp(i, 5 - i, :, :)) / 4;
end
accMean = mean(acc, 2);
bccMean = mean(bcc, 2);
accStd = std(acc, 0, 2);
bccStd = std(bcc, 0, 2);
plotWithStd((1:length(accMean)) * BIN / 1000, ...
    [accMean, bccMean], [accStd, bccStd]);
hold on;
plot([1 length(accMean)] * BIN / 1000, [1 / 4, 1 / 4], 'k');
text(BIN / 1000, 1 / 4, 'Chance level', 'VerticalAlignment', 'bottom');
title(sprintf('Decoding Accuracy (Trained between %.2fs and %.2fs)', ...
    dBegin, dEnd));
legend({'Acuuracy', 'Reversed'});
xlabel('Latency (s)');
ylabel('Accuracy');
ylim([0 1]);

