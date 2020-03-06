%% ERPstat - Figure out the significant effect in ERP
%
% Ruiqi Chen, 01/22/2020
%
% Using Fieldtrip cluster-level permutation test to determine the
%   significant difference in oscillatory power for the correct trials in four
%   conditions.
%

clear;clc;close all;

DFPATH = '../group/';
LAYOUTFILE = '../easycapM1.mat';
NEIGHBFILE = '../easycapM1_neighb.mat';
WINRANGE = [0.75 2.75];
USEBIN = 'on';
NBIN = 8;
CONDITIONS = {'Simple', 'Reversed', 'Transposition', 'Contour'};

timepoints = linspace(WINRANGE(1), WINRANGE(2), NBIN + 1);
nCond = length(CONDITIONS);


%% Import data

tmpDat = {};
allCond = [];
tmpSub = {};
grandSub = {};
for cond = 1:nCond
    load([DFPATH CONDITIONS{cond} 'T_ERP.mat'], 'allDat', 'allSub');
    tmpDat = [tmpDat allDat];
    allCond = [allCond cond * ones(1, length(allDat))];
    tmpSub = [tmpSub allSub];
    grandSub = union(grandSub, allSub);
end
clear allDat allSub
for i = 1:length(tmpSub)
    % bin the data
    if strcmp(USEBIN, 'on')
        if isfield(tmpDat{i}, 'var')
            tmpDat{i} = rmfield(tmpDat{i}, 'var');
        end
        if isfield(tmpDat{i}, 'dof')
            tmpDat{i} = rmfield(tmpDat{i}, 'dof');
        end
        avg = zeros(length(tmpDat{i}.label), NBIN);
        for j = 1:NBIN
            tmp1 = find(tmpDat{i}.time >= timepoints(j), 1);
            tmp2 = find(tmpDat{i}.time >= timepoints(j + 1), 1);
            avg(:, j) = mean(tmpDat{i}.avg(:, tmp1:tmp2), 2);
        end
        tmpDat{i}.time = (timepoints(1:NBIN) + timepoints(2:end)) / 2;
        tmpDat{i}.avg = avg;
    end
        
    tmpSub{i} = find(strcmp(tmpSub{i}, grandSub));
end
allSub = cell2mat(tmpSub);  % transform into double vector
allDat = tmpDat;
clear tmpDat tmpSub


%% Cluster-level ANOVA

cfg = struct();
cfg.latency = WINRANGE;
cfg.feedback = 'gui';
% one way repeated measure ANOVA over four conditions
%   for every (channel, bin/timepoint) pairs
% right tail F-test
cfg.statistic = 'depsamplesFunivariate';
cfg.computecritval = 'yes';
cfg.alpha = 0.05;
cfg.tail = 1;
% cluster-level permutation
cfg.method = 'montecarlo';
cfg.numrandomization = 2000;
cfg.correctm = 'cluster';
cfg.clusterstatistic = 'maxsum';
cfg.clusteralpha = 0.05;
cfg.clustertail = 1;
cfg.minnbchan = 2;
% define neighbour structure
cfg_neighb = [];
cfg_neighb.method = 'template';
cfg_neighb.layout = LAYOUTFILE;
cfg_neighb.template = NEIGHBFILE;
cfg.neighbours = ft_prepare_neighbours(cfg_neighb, allDat{1});
% define the design
cfg.design = [allSub; allCond];
cfg.uvar = 1;
cfg.ivar = 2;

[statF] = ft_timelockstatistics(cfg, allDat{:});

% % window of significant difference
% tmpInd = find(sum(statF.mask));
% WINOI = [statF.time(tmpInd(1)), statF.time(tmpInd(end))];
% % channels with consecutive significance
% chnInd = logical(min(statF.mask(:, tmpInd(1):tmpInd(end)), [], 2));
% ROI = statF.label(chnInd);


% %% Cluster-level T-test for OTHER vs SIMPLE (Bonferroni correction)
% 
% statT = cell(1, 4);
% for cond = 2:nCond
%     cfg = struct();
%     cfg.latency = WINOI;
%     cfg.channel = ROI;
%     cfg.feedback = 'gui';
%     % Repeated measures T-test for all other conditions vs Simple
%     %   for every (channel, bin/timepoint) pairs
%     cfg.statistic = 'depsamplesT';
%     cfg.computecritval = 'yes';
%     cfg.alpha = 0.025 / (nCond - 1);  % Bonferroni correction
%     cfg.tail = 0;
%     % cluster-level permutation
%     cfg.method = 'montecarlo';
%     cfg.numrandomization = 1000;
%     cfg.correctm = 'cluster';
%     cfg.clusterstatistic = 'maxsum';
%     cfg.clusteralpha = 0.025;
%     cfg.clustertail = 0;
%     cfg.minnbchan = 2;
%     % define neighbour structure
%     cfg_neighb = [];
%     cfg_neighb.method = 'template';
%     cfg_neighb.layout = LAYOUTFILE;
%     cfg_neighb.template = NEIGHBFILE;
%     cfg.neighbours = ft_prepare_neighbours(cfg_neighb, allDat{1});
%     % define the design
%     cfg.design = [allSub(or(allCond == 1, allCond == cond));...
%         1 + (allCond(or(allCond == 1, allCond == cond)) == 1)];
%     % make OTHER 1 and SIMPLE 2
%     cfg.uvar = 1;
%     cfg.ivar = 2;
% 
%     statT{cond} = ft_timelockstatistics(cfg, ...
%         allDat{or(allCond == 1, allCond == cond)});
% end


%% Plotting the result

% calculate the grand average for each condition
cfg = [];
cfg.channel   = 'all';
cfg.latency   = 'all';
cfg.parameter = 'avg';

grandDat = cell(1, nCond);
for i = 1:nCond
    grandDat{i} = ft_timelockgrandaverage(cfg, allDat{allCond == i});
end

% % plotting the voltage distribution
% figure;
% for cond = 1:nCond
%     subplot(nCond, 4, 4 * cond - 3);
%     cfg = [];
%     cfg.parameter = 'avg';
%     cfg.xlim = [0 WINRANGE(1)];
%     cfg.zlim = [-5 5];
%     cfg.colormap = jet;
%     cfg.comment = 'xlim';
%     cfg.commentpos = 'title';
%     cfg.layout = LAYOUTFILE;
%     ft_topoplotER(cfg, grandDat{cond});
%     colorbar;
%     
%     subplot(nCond, 4, 4 * cond - 2);
%     cfg.xlim = WINRANGE;
%     ft_topoplotER(cfg, grandDat{cond});
%     colorbar;
%     
%     subplot(nCond, 4, 4 * cond - 1);
%     cfg.xlim = [WINRANGE(2) WINRANGE(2) + WINRANGE(1)];
%     ft_topoplotER(cfg, grandDat{cond});
%     colorbar;
%     
%     subplot(nCond, 4, 4 * cond);
%     czMask = strcmp('Cz', grandDat{cond}.label);
%     timeMask = and(grandDat{cond}.time >= 0, ...
%         grandDat{cond}.time <= WINRANGE(2) + WINRANGE(1));
%     tmpCz = grandDat{cond}.avg(czMask, timeMask);
%     tmpvar = grandDat{cond}.var(czMask, timeMask);
%     tmpDof = grandDat{cond}.dof(1);
%     plot(grandDat{cond}.time(timeMask), tmpCz);
%     xlim([0 WINRANGE(2) + WINRANGE(1)]);
%     ylim([-5 5]);
%     title(sprintf("Cz ERP for %s", CONDITIONS{cond}));
% end
% sgtitle("Topoplot and Cz ERP");

% plotting the F-value
figure;
for i = 1:NBIN
    subplot(2, ceil(NBIN / 2), i);
    cfg = [];
    cfg.parameter = 'stat';
    cfg.xlim = timepoints([i i+1]);
    cfg.zlim = [0 statF.critval * 1.5];
    cfg.colormap = jet;
    cfg.comment = 'xlim';
    cfg.commentpos = 'title';
    hlChnInd = zeros(length(statF.label), 1);
    if strcmp(USEBIN, 'on')
        cfg.xlim = [1 1] * mean(timepoints([i i+1]));
        cfg.highlight = 'on';
        cfg.highlightsize = 8;
        cfg.highlightcolor = [1 1 1];
        if isfield(statF, 'posclusterslabelmat')
            hlChnInd = hlChnInd + statF.posclusterslabelmat(:, i);
        end
        cfg.highlightchannel = find(hlChnInd == 1);
    end
    cfg.layout = LAYOUTFILE;
    ft_topoplotER(cfg, statF);
    colorbar;
    if strcmp(USEBIN, 'on')
        title(sprintf("Bin=[%.2f %.2f]", timepoints(i), timepoints(i + 1)));
    end
end
if strcmp(USEBIN, 'on')
    sgtitle(sprintf("F-value topoplot (p = %.4f)", ...
        statF.posclusters(1).prob));
else
    sgtitle("F-value topoplot");
end

% % plotting the T-value
% for cond = 2:nCond
%     figure;
%     for i = 1:length(statT{2}.time)
%         subplot(2, ceil(length(statT{2}.time) / 2), i);
%         cfg = [];
%         cfg.parameter = 'stat';
%         cfg.xlim = timepoints([i i+1]);
%         cfg.zlim = statT{cond}.critval;
%         cfg.colormap = jet;
%         cfg.comment = 'xlim';
%         cfg.commentpos = 'title';
%         hlChnInd = zeros(length(statT{cond}.label), 1);
%         if strcmp(USEBIN, 'on')
%             cfg.xlim = [1 1] * mean(timepoints([i i+1]));
%             cfg.highlight = 'on';
%             cfg.highlightcolor = [1 1 1];
%             hlChnInd = hlChnInd + statT{cond}.mask(:, i);
%             cfg.highlightchannel = find(hlChnInd);
%         end
%         cfg.layout = LAYOUTFILE;
%         ft_topoplotER(cfg, statT{cond});
%         if any(hlChnInd)
%             text(-0.55, 0.65, sprintf("* p<%.2f", statT{cond}.cfg.alpha));
%         end
%         colorbar;
%         if strcmp(USEBIN, 'on')
%             title(sprintf("Bin=[%.2f %.2f]",...
%                 timepoints(i), timepoints(i + 1)));
%         end
%     end
%     sgtitle(sprintf("T-value of %s vs %s", ...
%         CONDITIONS{cond}, CONDITIONS{1}));
% end