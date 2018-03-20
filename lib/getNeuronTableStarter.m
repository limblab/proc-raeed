%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function neuronTable = getNeuronTableStarter(trial_data,params)
%
%   Gets weight table for given out_signal. You need to define the out_signal
%   This is basically a wrapper around getModel, to put weights into a nice
%       tabular format per neuron
%
% INPUTS:
%   trial_data : the struct
%   params     : parameter struct
%       .out_signal_names : names of signals to be used as signalID weightTable
%                           default - empty
% OUTPUTS:
%   neuronTable : neuron table starter (first few columns of a neuron table)
%
% Written by Raeed Chowdhury. Updated Nov 2017.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function neuronTable = getNeuronTableStarter(trial_data,params)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DEFAULT PARAMETERS
out_signal_names = {};
assignParams(who,params);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% get height of table
tab_height = size(out_signal_names,1);
if numel(unique(cat(1,{trial_data.monkey}))) > 1
    error('More than one monkey in trial data')
end
monkey = repmat({trial_data(1).monkey},tab_height,1);
if numel(unique(cat(1,{trial_data.date}))) > 1
    date = cell(tab_height,1);
    warning('More than one date in trial data')
else
    date = repmat({trial_data(1).date},tab_height,1);
end
if numel(unique(cat(1,{trial_data.task}))) > 1
    task = cell(tab_height,1);
    warning('More than one task in trial data')
else
    task = repmat({trial_data(1).task},tab_height,1);
end

neuronTable = table(monkey,date,task,out_signal_names,'VariableNames',{'monkey','date','task','signalID'});
