function compareTuning(curves,pds,which_units,maxFR,move_corIn)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   comares tuning between different conditions with empirical
%   tuning curves and PDs.
%   Inputs - 
%       curves - cell array of tuning curve tables, one table
%                   per condition
%       pds - cell array of PD tables, one table per condition
%       which_units - (optional) vector array unit indices to plot
%                   default - plots them all
%       maxFR - (optional) array of maximum firing rates to
%               display in polar plots. Default behavior is to
%               find maximum firing rate over all curve
%               conditions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Default Param
move_cor = 'vel';
% check maxFR input
if ~exist('maxFR','var') || isempty(maxFR)
    maxFR = [];
elseif numel(maxFR) == 1
    maxFR = repmat(maxFR,height(curves{1}));
elseif numel(maxFR) ~= height(curves{1})
    error('maxFR is wrong size')
end

if ~exist('which_units','var') || isempty(which_units)
    which_units = 1:height(curves{1});
elseif ~isvector(which_units)
    error('which_units needs to be vector')
end

% check cell nature of curves and pds
if ~iscell(curves) || ~iscell(pds)
    error('curves and pds must be cell arrays of tables')
end

% make curves a row cell array
curves = reshape(curves,1,length(curves)); % this should throw an error if it's not a 1-d cell array

if nargin >4, move_cor = move_corIn; end 
%% Plot tuning curves
% pick condition colors
cond_colors = linspecer(numel(curves));
% number of subplots (include plot for legends)
n_rows = ceil(sqrt(length(which_units)+1));
% get signal ID
signalID = curves{1}.signalID;
% get maxFR for each neuron
maxFR = max(cell2mat(cellfun(@(x) x.([move_cor 'CurveCIHi']),curves,'UniformOutput',false)),[],2);
% make plots
for neuron_idx = 1:length(which_units)
    subplot(n_rows,n_rows,neuron_idx)
    for cond_idx = 1:numel(curves)
        pdTable = pds{cond_idx};
        curveTable = curves{cond_idx};
        plotFlatTuning(pdTable(which_units(neuron_idx),:),curveTable(which_units(neuron_idx),:),maxFR(which_units(neuron_idx)),cond_colors(cond_idx,:),[], move_cor);
        % plotTuning(pdTable(which_units(neuron_idx),:),curveTable(which_units(neuron_idx),:),maxFR(which_units(neuron_idx)),cond_colors(cond_idx,:),[], move_cor);
        hold on
    end
    if isnumeric(signalID(which_units(neuron_idx)))
        label = ['Neuron ' num2str(signalID(which_units(neuron_idx)))];
    else
        label = ['Neuron ' signalID(which_units(neuron_idx))];
    end

    title(label)
end

subplot(n_rows,n_rows,n_rows^2)
for cond_idx = 1:numel(curves)
    plot([0 1],repmat(cond_idx,1,2),'-','linewidth',2,'color',cond_colors(cond_idx,:))
    hold on
end
ylabel 'Condition number'
set(gca,'box','off','tickdir','out','xtick',[],'ytick',1:numel(curves))
