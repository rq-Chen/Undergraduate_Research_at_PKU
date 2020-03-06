%% TFstat - Figure out the significant effect in time-frequency
%
% Ruiqi Chen, 03/02/2020
%
% Using Fieldtrip cluster-level permutation test to determine the
%   significant difference in time-frequency for the correct trials in four
%   conditions.
%


clear;clc;close all;

DFPATH = '../group/';
LAYOUTFILE = '../easycapM1.mat';
NEIGHBFILE = '../easycapM1_neighb.mat';
WINRANGE = [0.75 2.75];
USEBIN = 'off';
NBIN = 8;
ROI = {'P*'};
FOI = {[4, 7], [8, 12], [13, 30]};
FOINAME = {'\theta', '\alpha', '\beta'};
CONDITIONS = {'Simple', 'Reversed', 'Transposition', 'Contour'};

timepoints = linspace(WINRANGE(1), WINRANGE(2), NBIN + 1);
nCond = length(CONDITIONS);


%% Import data

tmpDat = {};
allCond = [];
tmpSub = {};
grandSub = {};
for cond = 1:nCond
    load([DFPATH CONDITIONS{cond} 'T_TF.mat'], 'allDat', 'allSub');
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


%% Plotting the result

% calculate the grand average for each condition

grandDat = cell(1, nCond);
grandDiff = cell(1, nCond);
for i = 1:nCond
    grandDat{i} = ft_freqgrandaverage(struct('toilim', [0 WINRANGE(2)]),...
        allDat{allCond == i});
    if i > 1
        grandDiff{i} = ft_math(struct('parameter', 'powspctrm', 'operation', 'subtract'),...
            grandDat{i}, grandDat{1});
    end
end

% Time-freqncy
figure;
for cond = 1:nCond
    subplot(1, nCond, cond);
    cfg = struct();
    cfg.channel = ROI;
    cfg.colorbar = 'no';
    cfg.xlim = WINRANGE;
    cfg.zlim = [-3 3];
    cfg.title = sprintf('%s', CONDITIONS{cond});
    ft_singleplotTFR(cfg, grandDat{cond});
    hold on;
%     for lineInd = 1:2
%         plot(WINRANGE(lineInd) * [1 1], ...
%             [grandDat{cond}.freq(1) grandDat{cond}.freq(end)], '--k');
%     end
end
ROIstr = strjoin(ROI, ', ');
sgtitle(['Time frequency result, averaged over channels ' ROIstr]);


% % Time-frequency difference
% figure;
% for cond = 2:nCond
%     subplot(1, nCond - 1, cond - 1);
%     cfg = struct();
%     cfg.channel = ROI;
%     cfg.colorbar = 'no';
%     cfg.xlim = WINRANGE;
%     cfg.zlim = [-2 2];
%     cfg.title = sprintf('%s - %s', CONDITIONS{cond}, CONDITIONS{1});
%     ft_singleplotTFR(cfg, grandDat{cond});
%     hold on;
% %     for lineInd = 1:2
% %         plot(WINRANGE(lineInd) * [1 1], ...
% %             [grandDat{cond}.freq(1) grandDat{cond}.freq(end)], '--k');
% %     end
% end
% ROIstr = strjoin(ROI, ', ');
% sgtitle(['Time frequency result, averaged over ' ROIstr]);

% Band power
figure;
for cond = 1:nCond
    for fInd = 1:length(FOI)
        subplot(length(FOI), nCond, cond + nCond * fInd - nCond);
        cfg = struct('layout', LAYOUTFILE);
        cfg.xlim = WINRANGE;
        cfg.ylim = FOI{fInd};
%         cfg.highlight = 'on';
%         cfg.highlightchannel = ROI;
%         cfg.highlightsymbol = '*';
        cfg.comment = 'no';
        cfg.zlim = [-2.5 2.5];
        ft_topoplotTFR(cfg, grandDat{cond});
        if fInd ~= 1
            title(sprintf('%s', FOINAME{fInd}));
        else
            title(sprintf('%s %s', CONDITIONS{cond}, FOINAME{fInd}));
        end
    end    
end
sgtitle("Power in each band");

% Band power difference
figure;
for cond = 2:nCond
    for fInd = 1:length(FOI)
        subplot(length(FOI), nCond - 1, cond - 1 + (nCond - 1) * (fInd - 1));
        cfg = struct('layout', LAYOUTFILE);
        cfg.xlim = WINRANGE;
        cfg.ylim = FOI{fInd};
%         cfg.highlight = 'on';
%         cfg.highlightchannel = ROI;
%         cfg.highlightsymbol = '*';
        cfg.comment = 'no';
        cfg.zlim = [-1.5 1.5];
        ft_topoplotTFR(cfg, grandDiff{cond});
        if fInd ~= 1
            title(sprintf('%s', FOINAME{fInd}));
        else
            title(sprintf('%s - %s %s', CONDITIONS{cond}, CONDITIONS{1},...
                FOINAME{fInd}));
        end
    end    
end
sgtitle("Power difference in each band");


%% Cluster-level ANOVA

% collapse the data within each band
for i = 1:length(allDat)
    newft = zeros(size(allDat{i}.powspctrm, 1), length(FOI),...
        size(allDat{i}.powspctrm, 3));
    newfreq = zeros(length(FOI), 1);
    for fInd = 1:length(FOI)
        lb = find(allDat{i}.freq >= FOI{fInd}(1), 1);
        gb = find(allDat{i}.freq >= FOI{fInd}(2), 1);
        newft(:, fInd, :) = mean(allDat{i}.powspctrm(:,lb:gb,:), 2);
        newfreq(fInd) = mean(FOI{fInd});
    end
    allDat{i}.powspctrm = newft;
    allDat{i}.freq = newfreq;
end

cfg = struct();
cfg.latency = WINRANGE;
cfg.avgovertime = 'yes';
cfg.feedback = 'gui';
% one way repeated measure ANOVA over four conditions
%   for every (channel, band) pairs
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

[statF] = ft_freqstatistics(cfg, allDat{:});

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

% Band power Statistics
figure;
for fInd = 1:length(FOI)
    subplot(1, length(FOI), fInd);
    cfg = struct('layout', LAYOUTFILE);
    cfg.ylim = mean(FOI{fInd}) * [1 1];
    cfg.zlim = [0 statF.critval];
    hlChnInd = zeros(length(statF.label), 1);
    cfg.highlight = 'on';
    cfg.highlightsize = 8;
    cfg.highlightcolor = [1 1 1];
    if isfield(statF, 'posclusterslabelmat')
        hlChnInd = hlChnInd + statF.posclusterslabelmat(:, i);
    end
    cfg.highlightchannel = find(hlChnInd == 1);
    cfg.parameter = 'stat';
    ft_topoplotTFR(cfg, statF);
    title(sprintf('%s', FOINAME{fInd}));
end  
sgtitle("Power in each band");