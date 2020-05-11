%% ERPPlot.m - Plot ERP
%
% Ruiqi Chen, 03/16/2019

clear;clc;close all;


%% Parameters

DFPATH = '../group/';
TOI = [-0.5 3];
ROI = 'P1';  % Draw picture for this channel

% conditions name, the first one will be subtracted from others
CONDITIONS = {'Simple', 'Reversed', 'Transposition', 'Contour'};
TOF = 'T';


%% Get Data

allERP = cell(size(CONDITIONS));
for i = 1:length(CONDITIONS)
    load([DFPATH CONDITIONS{i} TOF '_ERP.mat'], 'allDat');
    allERP{i} = ft_timelockgrandaverage(struct(), allDat{:});
end
clear allDat


%% Illustration

ROIIND = find(strcmp(ROI, allERP{1}.label));
if isempty(ROIIND)
    error("%s is not a valid channel label!\n", ROI);
end
nCond = length(CONDITIONS);
timeMask = and(allERP{1}.time >= TOI(1), allERP{1}.time <= TOI(2));
allTime = allERP{1}.time(timeMask);
nTime = length(allTime);

meanERP = zeros(nCond, nTime);
semERP = zeros(nCond, nTime);
for cond = 1:nCond
    meanERP(cond,:) = allERP{cond}.avg(ROIIND, timeMask);
    semERP(cond,:) = sqrt(allERP{cond}.var(ROIIND, timeMask) ./ allERP{cond}.dof(ROIIND, timeMask));
end

figure; hold on;
colmat = lines;
for cond = 1:nCond
    plot(allTime, meanERP(cond,:), 'Color', colmat(cond,:));
end
for cond = 1:nCond
    fill([allTime allTime(end:-1:1)], ...
        [meanERP(cond, :) + semERP(cond, :) ...
        meanERP(cond,end:-1:1)- semERP(cond,end:-1:1)],...
        colmat(cond,:), 'EdgeColor','none','FaceAlpha',0.15);    
end
plot([0 0], ylim(), 'k');
plot([0.25 0.25], ylim(), 'k');
plot([0.5 0.5], ylim(), 'k');
plot([0.75 0.75], ylim(), 'k');
plot([2.75 2.75], ylim(), 'k');
legend(CONDITIONS);
title([ROI ' ERPs']);