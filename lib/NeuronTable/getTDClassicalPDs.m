%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function pdTable = getTDClassicalPDs(trial_data,params)
%
%   Gets PD table for given out_signal. You need to define the out_signal
% and move_corr parameters at input. This computes the PD with a circular
% mean of the direction of move_corr, weighted by the firing rate.
%
% INPUTS:
%   trial_data : the struct
%   params     : parameter struct
%       .out_signals  : which signals to calculate PDs for
%       .out_signal_names : names of signals to be used as signalID pdTable
%                           default - empty
%       .trial_idx    : trials to use.
%                         DEFAULT: 1:length(trial_data
%       .in_signals   : which signals to calculate PDs on
%                           note: each signal must have only two columns for a PD to be calculated
%                           default - 'vel'
%       .prefix       : prefix to add before column names
%       .do_plot      : plot of directions for diagnostics, not for general
%                       use.
%
% OUTPUTS:
%   pdTable : calculated PD table, including columns for PDs, PDCI, and for whether neuron is tuned
%
% Written by Raeed Chowdhury. Updated Nov 2017.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function pdTable = getTDClassicalPDs(trial_data,params)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DEFAULT PARAMETERS
out_signals      =  [];
in_signals      = 'vel';
prefix = '';
do_plot = false;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Some undocumented parameters
alpha_cutoff = 0.05;
num_boots = 1000;

if nargin > 1, assignParams(who,params); end % overwrite parameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Process inputs
assert(~isempty(out_signals),'Need to provide output signal')

out_signals = check_signals(trial_data(1),out_signals);
num_out_signals = sum(cellfun(@(x) length(x),out_signals(:,2)));

in_signals = check_signals(trial_data(1),in_signals);
num_in_signals = size(in_signals,1);
for i = 1:num_in_signals
    assert(length(in_signals{i,2})==2,'Each element of in_signals needs to refer to only two column covariates')
end

if ~isempty(prefix)
    if ~endsWith(prefix,'_')
        prefix = [prefix '_'];
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% preallocate final table
pdTable_cell = cell(1,num_in_signals*3);
for in_signal_idx = 1:num_in_signals
    % extract signals
    inArr = get_vars(trial_data,in_signals(in_signal_idx,:));
    inDir = atan2(inArr(:,2),inArr(:,1));
    outArr = get_vars(trial_data,out_signals);

    % loop over each out_signal to get PDs and tuned-ness
    PD = zeros(num_out_signals,1);
    PDCI = zeros(num_out_signals,2);
    isTuned = false(num_out_signals,1);
    if do_plot
        figure
    end
    sig_tic = tic;
    for out_signal_idx = 1:num_out_signals
        % Calculate mean direction of in_signal weighted by firing rate of neuron
        [PD(out_signal_idx), PDCI(out_signal_idx,2), PDCI(out_signal_idx,1)] = circ_mean(inDir,outArr(:,out_signal_idx));

        % Figure out if out_signal is tuned
        % first define a function to use in bootstrapping
        r_func = @(x) circ_r(x,outArr(:,out_signal_idx));
        r_true = r_func(inDir);

        % Bootstrap a scrambled r
        r_scramble = bootstrp(num_boots,@(x) r_func(x),inDir);
        scramble_high = prctile(r_scramble,(1-alpha_cutoff)*100);

        % check if tuned
        isTuned(out_signal_idx) = (r_true > scramble_high);

        % diagnostic info
        fprintf('Evaluated signal %d of %d at time %f\n',out_signal_idx,num_out_signals,toc(sig_tic))
        if do_plot
            % plot?
            scatter(r_scramble,out_signal_idx*ones(size(r_scramble,1),1),[],'k','filled')
            hold on
            scatter(r_true,out_signal_idx,[],'r','filled')
        end
    end
    if do_plot
        axis ij
        title(sprintf('Scramble plot for %s',in_signals{in_signal_idx,1}))
    end
    pdTable_cell{in_signal_idx} = table(PD,PDCI,isTuned,...
        'VariableNames',strcat([prefix in_signals{in_signal_idx,1}],{'PD','PDCI','Tuned'}));
end
starter = makeNeuronTableStarter(trial_data,params);
pdTable = horzcat(starter,pdTable_cell{:});
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
