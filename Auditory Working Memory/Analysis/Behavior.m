%% Behavior.m - Behavioral Statistics
%
% Ruiqi Chen, 01/21/2020
%
% Compute the behavioral statistics

clear;clc;close all;


%% Parameters

DFPATH = '../../';
nBlock = 8;
nSub = 8;
latincondition = [1 3 2 4 2 1 4 3 1 3 2 4 2 1 4 3];    % latin square

% conditions name
CONDITIONS = {'Simple', 'Reversed', 'Transposition', 'Contour'};
nCond = length(CONDITIONS);


%% Get folders

allDir = dir(DFPATH);
isFolder = [allDir.isdir];
Folders = {allDir.name};
Folders = Folders(isFolder);
Folders = Folders(3:end);  % skip .\ and ..\


%% Computation

% accuracy and RT
allACC = nan(nCond, nSub);
allRT = nan(nCond, 2, nSub);

subInd = 0;
for currFold = Folders
    
    currSub = currFold{1};
    DATFILE = [DFPATH currSub '/' currSub '.mat'];
    if size(dir(DATFILE), 1) == 0
        warning("File missing. Folder %s is skipped.\n", currSub);
        continue;
    end
    subInd = subInd + 1;
    
    load(DATFILE, 'RT', 'TrialType', 'ResponseType', 'Subinfo');
    iblock = mod(str2num(Subinfo{2})-1 , 8)+1;
    allBlocks = latincondition(iblock:iblock+nBlock-1);
    subACC = (ResponseType == TrialType);
    
    for cond = 1:nCond
        allACC(cond, subInd) = mean(subACC(allBlocks == cond, :), 'all');
        condTorF = subACC(allBlocks == cond, :)';
        condTorF = condTorF(:);
        condRT = RT(allBlocks == cond, :)';
        condRT = condRT(:);
        allRT(cond, 1, subInd) = mean(condRT(condTorF));  % correct
        allRT(cond, 2, subInd) = mean(condRT(~condTorF)); % wrong
    end
    
end


%% Plotting

% accuracy (all subjects)
figure;
bar(mean(allACC, 2));
hold on;
errorbar(mean(allACC, 2), std(allACC, 0, 2) / sqrt(nSub), '.');
xticklabels(CONDITIONS);
title(sprintf("Accuracy (n = %d, p-value corrected by Tukey's hsd)", nSub))
sigline([1,2],1,'n.s.')
sigline([3,4],1)
sigline([2,4],gca)

% RT (some missing because of 100% accuracy)
figure;
Bars = bar(squeeze(mean(allRT, 3, 'omitnan')));
hold on; 
tmp = (1:4) + Bars(1).XOffset;
errorbar(tmp,squeeze(mean(allRT(:,1,:), 3, 'omitnan')),...
    squeeze(std(allRT(:,1,:), 0, 3, 'omitnan')) / sqrt(nSub), '.k');
tmp = (1:4) + Bars(2).XOffset;
errorbar(tmp,squeeze(mean(allRT(:,2,:), 3, 'omitnan')),...
    squeeze(std(allRT(:,2,:), 0, 3, 'omitnan')) / sqrt(nSub), '.k');
xticks(1:4);
xticklabels(CONDITIONS);
sigline([3,4],gca,'*', 'p = 0.05')
sigline([1,4],gca,'*', 'p = 0.06')
title("Reaction time (main effect of response: p<0.01)");
legend({'Correct', 'Incorrect'});


%% Statistics

[~, ~, stat] = anova1(allACC', CONDITIONS, 'off');
cAcc = multcompare(stat, 'Display','off');

allCOND = cell(nCond, 2, nSub);
allTF = allCOND;
for i = 1:nCond
    allCOND(i,:,:) = CONDITIONS(i);
end
allTF(:,1,:) = {'Correct'};
allTF(:,2,:) = {'Incorrect'};
[~, ~, stat] = anovan(allRT(:), {allCOND(:), allTF(:)},...
    'varnames',{'Task','Response'}, 'display', 'off');
cRT = multcompare(stat, 'Display','off');