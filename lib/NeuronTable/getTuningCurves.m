% GETTUNINGCURVES Gets tuning curves for firing rate against
% move_var. Outputs curve in 8 bins, along with high and low CI.
% INPUTS - 
%   trial_data - trial_data struct on which to operate
%   params - parameters struct
%       .out_signals - signal to get tuning curves for (usually firing rates)
%       .out_signal_names : names of signals to be used as signalID pdTable
%                           default - empty
%       .use_trials    : trials to use.
%                         DEFAULT: 1:length(trial_data
%       .move_corr - movement correlate to find tuning to
%                    options:
%                           'vel' : velocity of handle (default)
%                           'acc' : acceleration of handle
%                           'force'  : force on handle
%       .num_bins - number of directional bins (default: 8)
% OUTPUTS -
%   curves - table of tuning curves for each column in signal, with 95% CI
%
% Written by Raeed Chowdhury. Updated Jul 2017.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [curves] = getTuningCurves(trial_data,params)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DEFAULT PARAMETERS
out_signals      =  [];
out_signal_names = {};
use_trials        =  1:length(trial_data);
move_corr      =  'vel';
num_bins        = 8;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Some undocumented parameters?
if nargin > 1, assignParams(who,params); end % overwrite parameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
possible_corrs = {'vel','acc','force'};
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Process inputs
trial_data = trial_data(use_trials);
if isempty(out_signals), error('Need to provide output signal'); end
if isempty(move_corr), error('Must provide movement correlate.'); end
if ~any(ismember(move_corr,possible_corrs)), error('Correlate not recognized.'); end
out_signals = check_signals(trial_data(1),out_signals);
response_var = get_vars(trial_data,out_signals);
move_corr = check_signals(trial_data(1),move_corr);
move_var = get_vars(trial_data,move_corr);

if numel(unique(cat(1,{trial_data.monkey}))) > 1
    error('More than one monkey in trial data')
end
monkey = repmat({trial_data(1).monkey},size(response_var,2),1);
if numel(unique(cat(1,{trial_data.date}))) > 1
    date = cell(size(response_var,2),1);
    warning('More than one date in trial data')
else
    date = repmat({trial_data(1).date},size(response_var,2),1);
end
if numel(unique(cat(1,{trial_data.task}))) > 1
    task = cell(size(response_var,2),1);
    warning('More than one task in trial data')
else
    task = repmat({trial_data(1).task},size(response_var,2),1);
end

out_signal_names = reshape(out_signal_names,size(response_var,2),[]);

% get bins
bins = linspace(-pi,pi,num_bins+1);
bins = bins(2:end);
bin_spacing = unique(diff(bins));
if numel(bin_spacing)>1
    error('Something went wrong...')
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
dir = atan2(move_var(:,2),move_var(:,1));
spd = sqrt(sum(move_var.^2,2));

% bin directions
dir_bins = round(dir/bin_spacing)*bin_spacing;
dir_bins(dir_bins==-pi) = pi;

% find response_var in each bin, along with CI
for i = 1:length(bins)
    % get response_var when move_var is in the direction of bin
    % Also transpose response_var so that rows are neurons and columns are observations
    response_var_in_bin = response_var(dir_bins==bins(i),:)';

    % Mean binned response_var has normal-looking distribution (checked with
    % bootstrapping on a couple S1 neurons)
    binnedResponse(:,i) = mean(response_var_in_bin,2); % mean firing rate
    binned_stderr = std(response_var_in_bin,0,2)/sqrt(size(response_var_in_bin,2)); % standard error
    tscore = tinv(0.975,size(response_var_in_bin,2)-1); % t-score for 95% CI
    binned_CIhigh(:,i) = binnedResponse(:,i)+tscore*binned_stderr; %high CI
    binned_CIlow(:,i) = binnedResponse(:,i)-tscore*binned_stderr; %low CI
end

% set up output struct
curves = table(monkey,date,task,out_signal_names,repmat(bins,size(response_var,2),1),binnedResponse,binned_CIlow,binned_CIhigh,...,
        'VariableNames',{'monkey','date','task','signalID','bins','binnedResponse','CIlow','CIhigh'});

end%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
