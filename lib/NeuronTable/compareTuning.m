function compareTuning(curves,pds,params)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   comares tuning between different conditions with empirical
%   tuning curves and PDs.
%   Inputs - 
%       curves - cell array of tuning curve tables, one table
%                   per condition
%       pds - cell array of PD tables, one table per condition
%       params - parameters struct
%           .which_units - (optional) vector array unit indices to plot
%                       default - plots them all
%           .maxFR - (optional) array of maximum firing rates to
%                   display in polar plots. Default behavior is to
%                   find maximum firing rate over all curve
%                   conditions
%           .move_corr - move correlate to compare tuning over
%               (default - 'vel')
%           .cond_colors - colors for conditions
%               (default - linspecer(num_conditions)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% initial check
assert(iscell(curves) && iscell(pds),'Curves and PDs must be passed in as cell arrays')

% Default Params
which_units = 1:height(curves{1});
move_corr = 'vel';
cond_colors = linspecer(numel(curves));
% get maxFR for each neuron
maxFR = max(cell2mat(cellfun(@(x) x.([move_corr 'CurveCIhigh']),curves,'UniformOutput',false)),[],2);

if nargin > 2, assignParams(who,params); end % overwrite parameters

% check inputs
if numel(maxFR) == 1
    maxFR = repmat(maxFR,height(curves{1}),1);
end
assert(isempty(maxFR) || numel(maxFR)==height(curves{1}),'maxFR is wrong size')
assert(isvector(which_units),'which_units needs to be vector')
assert(size(cond_colors,1)==numel(curves),'Number of colors must match number of conditions')

% make curves a row cell array
curves = reshape(curves,1,length(curves)); % this should throw an error if it's not a 1-d cell array

%% Plot tuning curves
% number of subplots (include plot for legends)
n_rows = ceil(sqrt(length(which_units)+1));
% get signal ID
signalID = curves{1}.signalID;
% make plots
for neuron_idx = 1:length(which_units)
    subplot(n_rows,n_rows,neuron_idx)
    for cond_idx = 1:numel(curves)
        pdTable = pds{cond_idx};
        curveTable = curves{cond_idx};
        % plotFlatTuning(pdTable(which_units(neuron_idx),:),curveTable(which_units(neuron_idx),:),...
        %     maxFR(which_units(neuron_idx)),cond_colors(cond_idx,:),[], move_corr);
        % plotTuning(pdTable(which_units(neuron_idx),:),curveTable(which_units(neuron_idx),:),...
        %     maxFR(which_units(neuron_idx)),cond_colors(cond_idx,:),[], move_corr);
        % plot only PDs
        plotTuning(pdTable(which_units(neuron_idx),:),[],...
            maxFR(which_units(neuron_idx)),cond_colors(cond_idx,:),[], move_corr);
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
