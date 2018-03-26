%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function pdTable = getPDsFromWeights(weightTable,params)
%
%   Gets PD table for given out_signal. You need to define the out_signal
% and move_corr parameters at input.
%
% INPUTS:
%   weightTable : the neuron table that contains weights calculated from model
%
% OUTPUTS:
%   pdTable : calculated PD table with CIs
%
% Written by Raeed Chowdhury. Updated Nov 2017.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function pdTable = getPDsfromWeights(weightTable,params)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% preallocate final table
% get neuron table starter from weight table
weight_cols = endsWith(weightTable.Properties.VariableNames,'Weight') & ~contains(weightTable.Properties.VariableNames,'baseline');
pdTable = weightTable(:,~weight_cols);
weight_cols_idx = find(weight_cols);
% add columns to pdTable for each input signal
for in_signal_idx = 1:length(weight_cols_idx)
    col_title = weightTable.Properties.VariableNames{weight_cols_idx(in_signal_idx)};
    in_signal_name = extractBefore(col_title,'Weight');
    weights = weightTable.(col_title);
    [th,r] = cart2pol(weights(:,1),weights(:,2));
    tab_append = table(th,r,'VariableNames',{[in_signal_name 'PD'],[in_signal_name 'Moddepth']});
    pdTable = [pdTable tab_append];
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
