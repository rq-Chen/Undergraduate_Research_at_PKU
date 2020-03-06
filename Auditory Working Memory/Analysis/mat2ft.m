function [timelock] = mat2ft(data, varargin)
%% mat2ft - organize matlab data into fieldtrip datatypes
%
% Currently only support ft_type_timelock.
%
% <strong>Input</strong>:
%
%       data: 2D or 3D double matrix, corresponding to label and time
%
% <strong>Key-value input</strong>:
%
%   You can specify eegfile for labels and time and optionally the chnInd.
%       "eegfile": a .set file containing label & time info
%       "chnInd":  nChan * 1 double vector, channel indices in EEG.chanlocs
%       "EOG": "on" or "off" (default), denoting whether the data contains
%           EOG channels. If specified as "on", channel label will be
%           imported from hdr.label instead of hdr.elec.label
%
%   You can also specify label & time explicitly:
%       "label": channel labels, nChan * 1 cell array of strings
%       "time": timpoints in each trial, nTime * 1 double vector
%
% <strong>Output</strong>:
%
%       timelock: ft_datatype_timelock with these fields:
%           dimord, label, time, trial/avg
%       
p = inputParser;
addParameter(p, 'eegfile', '', @(s)ischar(s)||isstring(s));
addParameter(p, 'chnInd', [], @isvector);
addParameter(p, 'label', {}, @iscellstr);
addParameter(p, 'time', [], @isvector);
addParameter(p, 'EOG', 'off', ...
    @(s)(ischar(s)||isstring(s)) && (strcmp(s, 'on') || strcmp(s, 'off')));
parse(p, varargin{:});

if ~isempty(p.Results.eegfile)
    hdr = ft_read_header(p.Results.eegfile);
    if strcmp(p.Results.EOG, 'off')
        timelock.label = hdr.elec.label;
    else   % use hdr.label if you want EOG
        timelock.label = hdr.label;
    end
    if ~isempty(p.Results.chnInd)
        timelock.label = timelock.label(p.Results.chnInd);
    end
    timelock.time = hdr.orig.times / 1000;   % from millisecond to second
else
    if isempty(p.Results.time) || isempty(p.Results.label)
        error('Label or time info missing.');
    end
    timelock.time = p.Results.time(:)';
    timelock.label = p.Results.label(:);
end

if ndims(data) == 3
    tmp1 = find(size(data) == length(timelock.label));
    tmp2 = find(size(data) == length(timelock.time));
    if isempty(tmp1) || isempty(tmp2)
        error('Input dimensions are incompatible.');
    end
    if length(tmp1) * length(tmp2) > 1
        warning("Dimensions with the same size! Assuming chn*time*trials!");
        tmp1 = 1;
        tmp2 = 2;
    end
    timelock.trial = permute(data, [6 - tmp1 - tmp2, tmp1, tmp2]);
    timelock.dimord = 'rpt_chan_time';
elseif ismatrix(data)
    tmp1 = find(size(data) == length(timelock.label));
    if isempty(tmp1)
        error('Input dimensions are incompatible.');
    end
    if length(tmp1) > 1
        warning("Dimensions with the same size! Assuming chn*time");
        tmp1 = 1;
    end
    timelock.avg = permute(data, [tmp1, 3 - tmp1]);
    timelock.dimord = 'chan_time';
end

end