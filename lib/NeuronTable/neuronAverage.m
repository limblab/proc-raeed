%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function [avg_data, cond_idx] = neuronAverage(neuronTable, keycols)
% 
% Averages over a NeuronTable structure for each given condition. Returns
% a new NeuronTable struct with one row per unique condition, with columns
% indicating mean, CIlow and CIhigh over the condition.
%
% Behaves very similar to trialAverage in TrialData structure
%
% INPUTS:
%   trial_data : the struct
%   keycols : (int array or cell array of strings) indices for the columns 
%       to be used as keys into the NeuronTable. This function will average over
%       all rows with the same key.
%
% OUTPUTS:
%   avg_data : struct representing average across trials for each condition
%   cond_idx : cell array containing indices for each condition
%
% EXAMPLES:
%   e.g. to average over all target directions and task epochs
%       avg_data = trialAverage(trial_data,{'target_direction','epoch'});
%       Note: gives a struct of size #_TARGETS * #_EPOCHS
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [avgTable,cond_idx] = neuronAverage(neuronTable, keycols)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Some undocumented extra parameters
if nargin > 2, assignParams(who,params); end % overwrite parameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
assert(nargin>1,'Key columns not provided as input.')

% transform keycols into logical index array for simplicity
if ~islogical(keycols)
    if isnumeric(keycols)
        keycols = ismember(1:width(neuronTable),keycols);
    else % it's probably a cell array of strings
        keycols = ismember(neuronTable.Properties.VariableNames,keycols);
    end
end
assert(any(keycols),'Key columns do not match given table')
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% loop along conditions and get unique values for each
keyTable = unique(neuronTable(:,keycols));
cond_idx = false(height(keyTable),height(neuronTable));
tab_append = cell(height(keyTable),1);
for key_idx = 1:height(keyTable)
    key = keyTable(key_idx,:);
    cond_idx(key_idx,:) = ismember(neuronTable(:,keycols),key);
    neuronTable_select = neuronTable(cond_idx(key_idx,:),:);
    dataTable = neuronTable_select(:,~keycols);
    meanTable = varfun(@mean,dataTable);
    
    % strip 'mean' from variable names
    meanTable.Properties.VariableNames = strrep(meanTable.Properties.VariableNames,'mean_','');

    % calculate confidence intervals
    ciLoArr = prctile(dataTable{:,:},2.5,1);
    ciHiArr = prctile(dataTable{:,:},97.5,1);

    ciLoTable = meanTable;
    ciHiTable = meanTable;
    ciLoTable{:,:} = ciLoArr;
    ciHiTable{:,:} = ciHiArr;
    ciLoTable.Properties.VariableNames = strcat(ciLoTable.Properties.VariableNames,'CILo');
    ciHiTable.Properties.VariableNames = strcat(ciHiTable.Properties.VariableNames,'CIHi');

    tab_append{key_idx} = horzcat(meanTable,ciLoTable,ciHiTable);
end
avgTable = horzcat(keyTable,vertcat(tab_append{:}));
