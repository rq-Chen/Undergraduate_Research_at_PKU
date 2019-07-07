%% avrDecoding.m - average the decoding result of all subjects

% Author: Ruiqi Chen

close all; clear;

load('../data/data_new.mat');
trange = [0 0.5];
allDec = zeros(6, 7, 600);  % 6 conditions * 7 channels * 600 timepoint

% average the coregistered response function of every subjects
% returned value of the external function ori_decode is based on each
% subject's performance under each conditions

for i = 1 : 6
    singleDec = zeros(7, 600);
    for j = 1 : 23
        singleDec = singleDec + ...
            ori_decode(j, i, trange(1), trange(2), eegdata, ang1_1);
    end
    singleDec = singleDec / 23;
    allDec(i,:,:) = singleDec;
    plotRes(singleDec, trange, i);
end

plotRes(squeeze(mean(allDec, 1)), trange, 0);  % further average it over 6 conditions
save('decRes.mat', 'allDec');


function [] = plotRes(decRes, trange, ind)

    ts = -0.5 : 0.01 : 5.49;
    chan_center = linspace(180 / 7, 180, 7);
    targ_ori = chan_center(4);
    tidx = ts >= trange(1) & ts <= trange(2);

    figure;
    subplot(1,2,1);hold on;
    imagesc(chan_center,ts, decRes');
    plot(targ_ori*[1 1],[ts(1) ts(end)],'k--');
    xlabel('Orientation channel (\circ)');
    ylabel('Time (s)');
    title('Coregistered channel response function timecourse');
    axis ij tight;

    subplot(1,2,2);
    plot(chan_center, mean(decRes(:, tidx), 2));
    xlabel('Orientation channel (\circ)');
    ylabel('Reconstructed channel response');
    title(sprintf('%d: Average (%0.01f-%0.01f s)', ind, trange(1),trange(2)));
    
end