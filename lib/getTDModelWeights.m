%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function weightTable = getTDModelWeights(trial_data,params)
%
%   Gets weight table for given out_signal. You need to define the out_signal
%   This is basically a wrapper around getModel, to put weights into a nice
%       tabular format per neuron
%
% INPUTS:
%   trial_data : the struct
%   params     : parameter struct
%       .out_signals  : which signals to calculate PDs for
%       .out_signal_names : names of signals to be used as signalID weightTable
%                           default - empty
%       .trial_idx    : trials to use.
%                         DEFAULT: 1:length(trial_data
%       .in_signals   : which signals to calculate PDs on
%                           note: each signal must have only two columns for a PD to be calculated
%                           default - 'vel'
%       .block_trials : (NOT IMPLEMENTED) if true, takes input of trial indices and pools
%                       them together for a single eval. If false, treats the trial indices
%                       like a list of blocked testing segments
%       .num_boots    : # bootstrap iterations to use
%       .distribution : distribution to use. See fitglm for options
%       .do_plot      : plot of directions for diagnostics, not for general
%                       use.
%
% OUTPUTS:
%   weightTable : calculated velocity PD table with CIs
%
% Written by Raeed Chowdhury. Updated Nov 2017.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function weightTable = getTDPDs(trial_data,params)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DEFAULT PARAMETERS
out_signals      =  [];
out_signal_names = {};
trial_idx        =  1:length(trial_data);
in_signals      = 'vel';
block_trials     =  false;
distribution = 'Poisson';
do_plot = false;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Some undocumented parameters
td_fn_prefix     =  '';    % prefix for fieldname
disp_times       = false; % whether to display compuation times
if nargin > 1, assignParams(who,params); end % overwrite parameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Process inputs
if isempty(out_signals), error('Need to provide output signal'); end

out_signals = check_signals(trial_data(1),out_signals);
response_var = get_vars(trial_data(trial_idx),out_signals);

in_signals = check_signals(trial_data(1),in_signals);
for i = 1:size(in_signals,1)
    if length(in_signals{i,2})~=2
        error('Each element of in_signals needs to refer to only two-column covariates')
    end
end
input_var = get_vars(trial_data(trial_idx),in_signals);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% preallocate final table
weightTable = getNeuronTableStarter(trial_data,params);
tab_append = table(zeros(size(response_var,2),1),'VariableNames',{'baselineWeight'});
weightTable = [weightTable tab_append];
for in_signal_idx = 1:size(in_signals,1)
    weightArr = zeros(size(response_var,2),size(in_signals{in_signal_idx,2},2));
    tab_append = table(weightArr, 'VariableNames',{[in_signals{in_signal_idx,1} 'Weight']});
    weightTable = [weightTable tab_append];
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Calculate model
model_params = struct('model_type',model_type,'model_name','temp',...
                            'in_signals',{in_signals},...
                            'out_signals',{out_signals},...
                            'add_pred_to_td',false);
[~,temp_info] = getModel(td_test{spacenum},model_params);
weights = temp_info.b';
% replace zeros with actual weights
weightTable{:,5:end} = weights;
