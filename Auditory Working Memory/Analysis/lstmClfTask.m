%% lstmClfTask.m - Use LSTM to classify the task types
%
% Ruiqi Chen, 04/16/2020
%

clear;clc;close all;


%% Parameters

DFPATH = '../';
STIFILE = 'StiNotes.mat';
TRAINFILE = 'trainDat.mat';
CHANLOCSFILE = '../chanlocs.mat';
fs = 500;
BIN = 50;  % in ms
timePoint = -4:0.002:5.998;
TOI = [0.75 2.75];
CONDITIONS = {'Simple', 'Reversed', 'Transposition', 'Contour'};
contType = [1 1; 1 -1; -1 1; -1 -1];

% Debugging
MODE = 'debug';

% For LSTM
nLSTMin = 8;
nHidU = 8;

% For training
valR = 0.2;
nEpochs = 30;
nBatchSize = 32;
LR = 1e-3;

% For illustration
cLim = [-0.3 0.3];
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

% load(RNNFILE, 'Layers');
Layers = [ ...
    sequenceInputLayer(64)
    fullyConnectedLayer(nLSTMin)
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
    if isempty(dir([DFPATH currSub '/' currSub 'ReversedT.mat']))
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
        otherNotes = cat(1, allNotes{:});
        otherData = cat(3, allData{:});
%         revNotes = allNotes{strcmp(CONDITIONS, 'Reversed')};
%         revData = allData{strcmp(CONDITIONS, 'Reversed')};
        
        otherType = zeros(size(otherNotes, 1), 1);
        tmp = 0;
        for i = 1:nCond
            otherType(tmp + 1 : tmp + size(allData{i}, 3)) = i;
            tmp = tmp + size(allData{i}, 3);
        end

        clear allNotes allData
        
        % Categorize each trial
        
%         revSign = sign(revNotes(:, 2:3) - revNotes(:, 1:2));
%         revType = zeros(size(revNotes, 1), 1);
%         for i = 1:length(revType)
%             for j = 1:4
%                 if isequal(revSign(i,:), contType(j,:))
%                     revType(i) = j;
%                     break
%                 end
%             end
%         end
%         otherSign = sign(otherNotes(:, 2:3) - otherNotes(:, 1:2));
%         otherType = zeros(size(otherNotes, 1), 1);
%         for i = 1:length(otherType)
%             for j = 1:4
%                 if isequal(otherSign(i,:), contType(j,:))
%                     otherType(i) = j;
%                     break
%                 end
%             end
%         end
        
        % slice data
        
%         revData = revData(:, indRange, :);
        otherData = otherData(:, indRange, :);
        trainX = cell(size(otherData, 3), binN);
        for i = 1:size(trainX, 1)
            for j = 1:size(trainX, 2)
                trainX{i, j} = squeeze(otherData(:, ...
                    (j - 1) * binPoint + 1 : j * binPoint, i));
            end
        end
%         testX = cell(size(revData, 3), binN);
%         for i = 1:size(testX, 1)
%             for j = 1:size(testX, 2)
%                 testX{i, j} = squeeze(revData(:, ...
%                     (j - 1) * binPoint + 1 : j * binPoint, i));
%             end
%         end
        trainY = categorical(repmat(otherType, 1, binN));
%         testY = categorical(repmat(revType, 1, binN));
        trainX = trainX(:); trainY = trainY(:);
%         testX = testX(:); testY = testY(:);
        
        % save data
        
        save([DFPATH currSub '/' TRAINFILE], ...
            'trainX', 'trainY'); %, 'testX', 'testY');
    else
        % load data
        fprintf('Loading data for %s ...\n', currSub);
        load([DFPATH currSub '/' TRAINFILE], ...
            'trainX', 'trainY'); %, 'testX', 'testY');
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
        'Plots','training-progress');
    lstmModel = trainNetwork(trainX, trainY, Layers, lstmOpt);
%     predP = predict(lstmModel, testX, 'ExecutionEnvironment', 'cpu');
%     predP = reshape(predP, [], binN, 4);

    % Calculate representation dissimilarity
    
%     neuRSM = nan(4, 4, binN);  % rows: S1 category; columns: predicted
%     revLabel = reshape(testY, [], binN);
%     revLabel = double(revLabel(:, 1));
%     for i = 1:4
%         neuRSM(i, :, :) = permute(mean(predP(revLabel == i, :, :)), ...
%             [1, 3, 2]);
%     end
%     allNeuRSM = [allNeuRSM neuRSM];
    
end


%% Illustration

% neuRSM = squeeze(mean(cat(4, allNeuRSM{:}), 4));
% fig = figure;
% timePoint = timePoint(timePoint >= 0);
% for i = 1:size(neuRSM, 3)
%     
%     imagesc(neuRSM(:,:,i));
%     xticks(1:4); xticklabels(CONDITIONS);
%     yticks(1:4); yticklabels(CONDITIONS);
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


%% Visualize the embedding layer

weights = lstmModel.Layers(2, 1).Weights;
load(CHANLOCSFILE, 'chanlocs');
fig = figure;
for i = 1:nLSTMin
    subplot(nLSTMin / 4, 4, i);
%     title(sprintf('Component %d', i));
    topoplot(weights(i,:), chanlocs);
    caxis(cLim);
end
sgtitle('Embedding projection');
