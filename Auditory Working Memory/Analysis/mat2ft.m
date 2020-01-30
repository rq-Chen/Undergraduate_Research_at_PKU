function [timelock] = mat2ft(data, label, time, varargin)
%% mat2ft - organize matlab data into fieldtrip datatypes
%
% Currently only support ft_type_timelock.
%
% Input:
%       data: 2D or 3D double matrix, corresponding to label and time
%       label: channel labels, nChan * 1 cell
%       time: timpoints in each trial, nTime * 1 double vector
%
% Key-value input:
%       "eegfile": specify a eeg data file containing channel info
%       "trialInd": nTrial * 1 double vector, the trial indices
%       "chanInd": nChan * 1 double vector, the channel indices
%       
p = inputParser;
addParameter(p, 'eegfile', '', @ischar);
addParameter(p, 'trialInd', [], @isvector);
addParameter(p, 'chanInd', [], @isvector);
parse(p, varargin{:});

if ndims(data) == 3
    tmp1 = find(size(data) == length(label));
    tmp2 = find(size(data) == length(time));
    timelock.trial = permute(data, [6 - tmp1 - tmp2, tmp1, tmp2]);
    timelock.dimord = 'rpt_chan_time';
elseif ndims(data) == 2
    tmp1 = find(size(data) == length(label));
    timelock.avg = permute(data, [tmp1, 3 - tmp1]);
    timelock.dimord = 'chan_time';
end

timelock.time = time(:)';
timelock.label = label(:);

end