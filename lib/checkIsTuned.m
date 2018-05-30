function [isTuned,isTunedPseudo] = checkIsTuned(trial_data,params)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CHECKISTUNED checks whether signals in trial data are
% sinusoidally tuned to a given 2-column correlate
%
% This function works by first computing the tuning curve
% (given the movement correlate, signals, and model type),
% and comparing the modulation depth of the tuning curve
% to a modulation depth that could be expected from randomly
% scrambled data.
%
% Inputs:
%   trial_data - data structure with all neural data and trials
%   params - 
%       .out_signals - names of signals to check
%       .in_signals - names of signals to correlate to (only 2 columns allowed)
%           (default: 'vel')
%       .alpha_cutoff - alpha value for modulation depth comparison to
%           scrambled data (default: 0.05)
%
% Outputs:
%   isTuned - logical array indicating which of the out_signals is tuned
%
% Written by Raeed Chowdhury 2018/04/12
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% DEFAULT PARAMETERS
in_signals = 'vel';
out_signals =  {};% {'name',idx};
alpha_cutoff = 0.05;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Here are some parameters that you can overwrite that aren't documented
glm_distribution     =  'poisson';   % which distribution to assume for GLM
num_boots = 1000; % number of bootstraps

if nargin > 1, assignParams(who,params); end % overwrite parameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Process inputs
assert(~isempty(out_signals),'output signals must be specified')
in_signals = check_signals(trial_data(1),in_signals);
in_arr = get_vars(trial_data,in_signals);
assert(size(in_arr,2) == 2,'move_corr must only have two columns')
out_signals = check_signals(trial_data(1),out_signals);
out_arr = get_vars(trial_data,out_signals);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Get model of neurons
num_out_signals = size(out_arr,2);
isTuned = false(num_out_signals,1);
isTunedPseudo = false(num_out_signals,1);

sig_tic = tic;
figure
for out_signal_idx = 1:num_out_signals
    % define functions
    moddepth_func = @(b) sqrt(sum(b(2:3).^2));
    bootfunc = @(x) glmfit(in_arr,x,glm_distribution);

    % get true moddepth
    b_true = bootfunc(out_arr(:,out_signal_idx));
    moddepth_true = moddepth_func(b_true);

    % get scrambled moddepth
    moddepth_scramble = bootstrp(num_boots,@(x) moddepth_func(bootfunc(x)),out_arr(:,out_signal_idx));

    % get CI high
    scramble_high = prctile(moddepth_scramble,(1-alpha_cutoff)*100);

    % check if tuned
    isTuned(out_signal_idx) = (moddepth_true > scramble_high);

    % check pseudo R2
    % out_hat = glmval(b_true,out_arr,'log');
    % isTunedPseudo(out_signal_idx) = (compute_pseudo_R2(out_arr(:,out_signal_idx),out_hat,mean(out_arr(:,out_signal_idx))) > 0);

    fprintf('Evaluated signal %d of %d at time %f\n',out_signal_idx,num_out_signals,toc(sig_tic))
    
    % plot?
    scatter(moddepth_scramble,out_signal_idx*ones(size(moddepth_scramble,1),1),[],'k','filled')
    hold on
    scatter(moddepth_true,out_signal_idx,[],'r','filled')
end


% get distribution of scrambled modulation depths

