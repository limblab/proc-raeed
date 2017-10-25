function compareTuning(curves,pds,maxFR)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   comares tuning between different conditions with empirical
%   tuning curves and PDs.
%   Inputs - 
%       curves - cell array of tuning curve tables, one table
%                   per condition
%       pds - cell array of PD tables, one table per condition
%       maxFR - (optional) array of maximum firing rates to
%               display in polar plots. Default behavior is to
%               find maximum firing rate over all curve
%               conditions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% check maxFR input
if ~exist('maxFR','var')
    maxFR = [];
else if numel(maxFR) == 1
    maxFR = repmat(maxFR,height(curves{1}));
else if numel(maxFR) ~= height(curves{1})
    error('maxFR is wrong size')
end

% check cell nature of curves and pds
if ~iscell(curves) || ~iscell(pds)
    error('curves and pds must be cell arrays of tables')
end

cond_colors = linspecer(numel(curves))
%% Plot tuning curves
for neuron_idx = 1:height(dl_curves)
    maxFR = max(cell2mat(cellfun(@(x) x.CIhigh,curves,'UniformOutput',false),2);
    for cond_idx = 1:numel(curves)
        height(curves{cond_idx},)
        plotTuning(bins,dl_pds(neuron_idx,:),dl_curves(neuron_idx,:),maxFR(neuron_idx),[1 0 0]);

        title(['Neuron ' num2str(neuron_idx)])
    end
end
