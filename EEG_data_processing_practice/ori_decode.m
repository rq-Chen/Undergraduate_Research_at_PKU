% ori_decode.m

% Gerneral Description:
% Author: Tommy Sprague, modified by Ruiqi Chen
% This function is a modification of the decoding model from Sprague (see
% the description below), which receives the selected input and output the
% decoding coefficient matrix.

% Data:
% The result has not been published yet. Generally speaking, I am trying to
% decode the orientation of a Gabor stimulus based on a visual working
% memory EEG experiment.

% Input:
% SUB_NO - number of the subject whose data is to be decoded
% TRN_NO - under which condition
% dStart, dEnd - time interval
% eegdata - 23 (participants) * 6 (conditions) * 140 (trials) * 65
% (channels) * 600 (timepoints)
% ang - the label of the data, 23 * 6 * 140
% ------------------------------------------------------------------------

% We should have use a preprocessed EEG data as the traing data (which
% means complex wavelet transformed and extract the coefficient at a
% specific band. But here we only use the raw data instead.

% Tommy Sprague, 3/16/2015, originally for Bernstein Center IEM workshop
% tommy.sprague@gmail.com or jserences@ucsd.edu
%
% Uses a dataset graciously donated by Edward Ester, results from which are
% in preparation for submission (edward.ester01@gmail.com).
%
% Please DO NOT use data from these tutorials without permission. Feel free
% to adapt or use code for teaching, research, etc. If possible, please
% acknowledge relevant publications introducing different components of these
% methods (Brouwer & Heeger, 2009; 2011; Sprague & Serences, 2013; Garcia
% et al, 2013; Sprague, Saproo & Serences, 2015)
%
% Previously (IEM_spatial.m) we leared about how to implement the IEM
% analysis pipeline for a "spatial" feature space. Then, in IEM_ori_fMRI.m
% we learned how to adapt this analysis pipeline to unidimensional feature
% values (orientation). Now we'll use the similar orientation IEM, but
% applied to EEG data acquired during steady state visual stimulation
% (steady state visually evoked potentials, SSVEP).

% Particpants performed a contrast change task on oriented gratings
% presented at one of 9 orientations.
% The advantage of  applying this method using EEG is we can reconstruct at
% each point in time (the data as given have been wavelet-transformed at the SSVEP
% frequency, 30 Hz).
%
% NOTE: the files loaded in this script are rather large (600-800 MB) and
% the model training/testing process will use significant amounts of RAM.
% If you're using an older computer, perhaps it may be easier to share with
% another class member w/ newer hardware.

function [cof] = ori_decode(SUB_NO, TRN_NO, dStart, dEnd, eegdata, ang)

close all;

ROOT = 'C:\Users\UserName\Documents\MATLAB\seq_color\';
addpath([ROOT 'IEM-tutorial-master\mFiles\']);

%% load data
%
% Each data file contains:
% - trn:  data used for encoding model estimation (contrast detection task)
%         n_trials x n_electrodes x n_timepoints wavelet coefficients
%         (complex, here we use real response for convenience)
%
% The wavelet coefficient represents the similarity between the basis
% wavelet function and the original signal. (Actually, in wavelet
% transforming, we represents a signal as the weighted sum (series) of some wavelet
% functions, and the wavelet coeeficients are the weights, namely the inner
% conduct (integration) between the signal and the wavelet functions)
%
% - trng: orientation label (0-160 deg) for each training trial
%       (remember it's a row vector!)
% - tst:  data used for orientation reconstruction (discrimination task)
%         n_trials x n_electrodes x n_timepoints wavelet coefficients
%         (complex, here real for convenience)
% - tstg: orientation label for each task trial (a row vector!)

% Note that the actual full dataset was measured at a 512 Hz sampling rate.
% If you're using the "full" file, ts(2)-ts(1) (sample period) will be
% (1/512) s. If you're using the "mini" file, I've subsampled the
% timepoints to make things more easily computable on slower hardware (like
% my laptop). Otherwise, the tutorial should work the same.

% % data generation constants
% SUB_NO = 11;  % using which subject's data
% TRN_NO = 5;  % using which condition as the training set

load([ROOT 'data\data_new.mat']);

% generating data
ts = -0.50 : 0.01 : 5.49;
trange = [dStart dEnd];  % look at this time window
trn = eegdata{1, SUB_NO}{1, TRN_NO};
trng = ang{1, SUB_NO}{1, TRN_NO};

%% generate orientation channels (orientation filters)
%
% Just like IEM_ori_fMRI.m, we need to choose a number of orientation
% channels.
%
% QUESTION: How many unique orientation channels can we model? Fill in the
% answer below, it will be used for the remainder of the script.

N_ORI_CHANS = 7;

% each orientation channel can be modeled as a "steerable filter" (see
% Freeman and Adelson, 1991), which here is a (co)sinusoid raised to a high
% power (specifically, N_ORI_CHANS-mod(N_ORI_CHANS,2)).

make_basis_function = @(xx,mu) (cosd(xx-mu)).^(N_ORI_CHANS-mod(N_ORI_CHANS,2));
% @ represents lambda function

% QUESTION: what is the bandwidth of each basis function (FWHM)? Can you
% write an expression which takes any arbitrary power and computes FWHM?

% Let's look at our channels.

xx = linspace(1,180,180);
basis_set = nan(180,N_ORI_CHANS);
chan_center = linspace(180/N_ORI_CHANS,180,N_ORI_CHANS);

for cc = 1:N_ORI_CHANS
    basis_set(:,cc) = make_basis_function(xx,chan_center(cc));
end

% figure;
% subplot(1,2,1);plot(xx,basis_set);
% title('Basis functions');
% ylabel('Filter amplitude (normalized)');
% xlabel('Orientation (\circ)');
%
% % now let's see how well the channels tile the space by summing them:
% subplot(1,2,2);plot(xx,sum(basis_set,2));
% title('Sum over orientation channels');
% ylabel('Summed filter amplitude');
% xlabel('Orientation (\circ)');



%% Build stimulus mask
%
% This is just like the orientation IEM for the EEG dataset. We'll just use
% the orientation in "trng" to generate stimulus masks for each training
% trial
%

trng = mod(trng,180);
trng(trng==0) = 180; % so that we can use positive integer to index into stimulus mask vector

stim_mask = zeros(length(trng),length(xx));

for tt = 1:size(stim_mask,1)  % loop over trials
    stim_mask(tt,trng(tt))=1;
    
end


% % let's check our stimulus mask
% figure;
% imagesc(stim_mask);%subplot(1,2,2);imagesc(stim_mask_R);
% title('Design matrix');
% xlabel('Orientation (\circ)');
% ylabel('Trial');


%% Generate design matrix
%
% We're modeling everything the same here as we did for IEM_ori_EEG.m -
% each voxel is modeled as a linear combination of a set of hypothetical
% neural populations, or information channels, which are modeled as
% orientation TFs (see above). The set of TFs forms our "basis set" (see
% above), which is used to generate predictions for how each channel should
% respond to any given stimulus value. Let's generate those predictions as
% a matrix of trials x channels, called a "design matrix"
%
% Because we've computed "stimulus images", we just need to project each
% stimulus image onto the N_ORI_CHANS basis functions.
%

trnX = stim_mask*basis_set;
% trnX is a 2D matrix with the nTrial cows and nChannel column, represents
% the predicted response of each channel in each trial (but it contains no
% temporal weights, which should be computed in the training process)


% As before, we need to be sure our design matrix is full rank (that is,
% all channels are non-colinear, and that we can uniquely estimate the
% contribution of each channel to the signal observed in a given voxel).

% fprintf('Design matrix rank = %i\n',rank(trnX));


% let's look at the predicted response for a single trial

% tr_num = 6;
% figure;
% subplot(1,3,1);hold on;
% plot(xx,basis_set);
% plot(xx,stim_mask(tr_num,:),'k-');
% xlabel('Orientation (\circ)');title(sprintf('Stimulus, trial %i',tr_num));
% xlim([0 180]);
% subplot(1,3,2);hold on;
% plot(chan_center,trnX(tr_num,:),'k-');
% for cc = 1:N_ORI_CHANS
%     plot(chan_center(cc),trnX(tr_num,cc),'o','MarkerSize',8,'LineWidth',3);
% end
% xlabel('Channel center (\circ)');title('Predicted channel response');
% xlim([-5 180]);
%
% % and the design matrix
%
% subplot(1,3,3);hold on;
% imagesc(chan_center,1:size(trnX,1),trnX);
% title('Design matrix');
% xlabel('Channel center (\circ)');ylabel('Trial'); axis tight ij;









%% Cross-validated training/testing on contrast discrimination task
%
% First, because trials are not evenly distributed across conditions and
% EEG measurement runs (after rejecting artifacts), we cannot be sure to
% have the same number of trials of each condition. A simple way to
% alleviate this is to truncate the training dataset so that there are
% min(n_trials_per_orientation) trials per orientation.


trn_ou = unique(trng);



trn_repnum = nan(size(trng));  % trial_n * trial_n
n_trials_per_orientation = nan(length(trn_ou),1);
for ii = 1:length(trn_ou)  % for each orientation in training set
    thisidx = trng==trn_ou(ii);
    trn_repnum(thisidx) = 1:(sum(thisidx));
    n_trials_per_orientation(ii) = sum(thisidx);
    clear thisidx;
end
% trn_repnum give each trial a repnum, ranging from 1 to n_reps. The trails
% are grouped according to stimuli.

trn_repnum(trn_repnum>min(n_trials_per_orientation))=NaN;
trng_cv = trng(~isnan(trn_repnum));

% cull all those trials from trn data (renamed trn_cv here for convenience)
trn_cv_coeffs = nan(sum(~isnan(trn_repnum)),2*size(trn,2),size(trn,3));
trn_cv_coeffs(:,1:size(trn,2),:) = real(trn(~isnan(trn_repnum),:,:));
trn_cv_coeffs(:,(size(trn,2)+1):(2*size(trn,2)),:) = imag(trn(~isnan(trn_repnum),:,:));
% extract the real and imag part of the actual response
% trn_number * (2*electrode_number) * time
trnX_cv = trnX(~isnan(trn_repnum),:);  % similar to tranX but less trials
trn_repnum = trn_repnum(~isnan(trn_repnum));

chan_resp_cv_coeffs = nan(size(trn_cv_coeffs,1),length(chan_center),size(trn_cv_coeffs,3));
% coeffiecient matrix, trial_number * chan_number * time_length

% Cross-validation: we'll do "leave-one-group-of-trials-out" cross
% validation by holding repnum==ii out at testset on each loop iteration

n_reps = max(trn_repnum(:));
% tic
for ii = 1:n_reps
    trnidx = trn_repnum~=ii;
    tstidx = trn_repnum==ii;
    
    thistrn = trn_cv_coeffs(trnidx,:,:);  % n-n_channel trials
    thistst = trn_cv_coeffs(tstidx,:,:);
    
    % loop over timepoints
    for tt = 1:size(thistrn,3)
        
        thistrn_tpt = thistrn(:,:,tt);
        thistst_tpt = thistst(:,:,tt);
        
        w_coeffs = trnX_cv(trnidx,:)\thistrn_tpt;
        % generally, it represents for this training trial and at this time,
        % the weight of each electrode in each channel
        
        chan_resp_cv_coeffs(tstidx,:,tt) = (w_coeffs.'\thistst_tpt.').';
        % Seems like computing the ratio of channel response and the model
        % of test response, at each time and for each test trial
    end
end
% toc

% trange = [0 0.5];
% tidx = ts >= trange(1) & ts <= trange(2); % only look at this window

%% plot data for cross-validated
%
% let's plot, as before, the reconstructions through time for each
% orientation separately
%



% figure; ax = [];
% for ii = 1:length(trn_ou)
%     ax(end+1) = subplot(2,length(trn_ou),ii); hold on;
%     
%     thisidx = trng_cv==trn_ou(ii);
%     imagesc(chan_center,ts,squeeze(mean(chan_resp_cv_coeffs(thisidx,:,:),1))');
%     % average the channel response coefficient over trials with the same stimulus
%     
%     plot([trn_ou(ii) trn_ou(ii)],[ts(1) ts(end)],'k--');
%     axis ij tight;
%     
%     title(sprintf('Ori: %i deg',trn_ou(ii)));
%     if ii == 1
%         ylabel('Time (s)');
%         xlabel('Orientation channel (\circ)');
%     end
%     set(gca,'XTick', 0:45:180);
%     
% end
% match_clim(ax);
% 
% % plot average from the window
% ax = [];
% tmean = mean(chan_resp_cv_coeffs(:,:,tidx),3);
% % average over time period
% for ii = 1:length(trn_ou)
%     ax(end+1) = subplot(2,length(trn_ou),ii+length(trn_ou)); hold on;
%     
%     thisidx = trng_cv==trn_ou(ii);
%     
%     plot(chan_center,mean(tmean(thisidx,:),1));
%     % average over group of trials
%     
%     %plot([trn_ou(ii) trn_ou(ii)],[ts(1) ts(end)],'k--');
%     %axis ij tight;
%     
%     title(sprintf('Ori: %i deg',trn_ou(ii)));
%     if ii == 1
%         ylabel('Channel response');
%         xlabel('Orientation channel (\circ)');
%     end
%     set(gca,'XTick', 0:45:180);
%     
% end
% match_ylim(ax);



%% now let's plot coregistered reconstructions
%
% for now, we'll do this in a simple way - let's adjust trials so that the
% correct orientation falls on the center of trn

targ_ori_idx = round(length(trn_ou)/2);
targ_ori = trn_ou(targ_ori_idx);

chan_resp_cv_coeffs_shift = nan(size(chan_resp_cv_coeffs));
for ii = 1:length(trn_ou)
    thisidx = trng_cv==trn_ou(ii);
    
    chan_resp_cv_coeffs_shift(thisidx,:,:) = circshift(chan_resp_cv_coeffs(thisidx,:,:), targ_ori_idx - ii, 2 );
end

cof = squeeze(mean(chan_resp_cv_coeffs_shift,1));

% figure;
% subplot(1,2,1);hold on;
% imagesc(chan_center,ts, cof');
% plot(targ_ori*[1 1],[ts(1) ts(end)],'k--');
% xlabel('Orientation channel (\circ)');
% ylabel('Time (s)');
% title('Coregistered channel response function timecourse');
% axis ij tight;
% 
% subplot(1,2,2);
% plot(chan_center, mean(cof(:, tidx), 2));
% xlabel('Orientation channel (\circ)');
% ylabel('Reconstructed channel response');
% title(sprintf('Average (%0.01f-%0.01f s)',trange(1),trange(2)));

end