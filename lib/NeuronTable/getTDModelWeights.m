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
%       .in_signals   : which signals to calculate PDs on
%                           note: each signal must have only two columns for a PD to be calculated
%                           default - 'vel'
%       .block_trials : (NOT IMPLEMENTED) if true, takes input of trial indices and pools
%                       them together for a single eval. If false, treats the trial indices
%                       like a list of blocked testing segments
%       .num_boots    : # bootstrap iterations to use
%       .model_type   : type of model to use (to be passed into getModel)
%                       default - 'glm'
%       .distribution : distribution to use. See fitglm for options
%       .prefix : prefix to add onto columns of weight table
%
% OUTPUTS:
%   weightTable : calculated velocity PD table with CIs
%
% Written by Raeed Chowdhury. Updated Nov 2017.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function weightTable = getTDModelWeights(trial_data,params)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DEFAULT PARAMETERS
out_signals      =  [];
trial_idx        =  1:length(trial_data);
in_signals      = 'vel';
model_type = 'glm';
distribution = 'Poisson';
prefix = '';
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Some undocumented parameters
if nargin > 1, assignParams(who,params); end % overwrite parameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Process inputs
if isempty(out_signals), error('Need to provide output signal'); end

out_signals = check_signals(trial_data(1),out_signals);
num_out_signals = sum(cellfun(@(x) length(x),out_signals(:,2)));

in_signals = check_signals(trial_data(1),in_signals);
for i = 1:size(in_signals,1)
    if length(in_signals{i,2})~=2
        error('Each element of in_signals needs to refer to only two-column covariates')
    end
end

if ~isempty(prefix)
    if ~endsWith(prefix,'_')
        prefix = [prefix '_'];
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% preallocate final table
weightTable = table(zeros(num_out_signals,1),'VariableNames',{[prefix 'baselineWeight']});
for in_signal_idx = 1:size(in_signals,1)
    weightArr = zeros(num_out_signals,size(in_signals{in_signal_idx,2},2));
    tab_append = table(weightArr, 'VariableNames',{[prefix in_signals{in_signal_idx,1} 'Weight']});
    weightTable = [weightTable tab_append];
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Calculate model
model_params = struct('model_type',model_type,'model_name','temp',...
                            'in_signals',{in_signals},...
                            'out_signals',{out_signals},...
                            'add_pred_to_td',false);
[~,temp_info] = getModel(trial_data,model_params);
weights = temp_info.b';
% replace zeros with actual weights
weight_width = size(weights,2);
weightTable{:,:} = weights;
