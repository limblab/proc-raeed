%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function pdTable = getTDPDs(trial_data,params)
%
%   Gets PD table for given out_signal. You need to define the out_signal
% and move_corr parameters at input.
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
%       .block_trials : (NOT IMPLEMENTED) if true, takes input of trial indices and pools
%                       them together for a single eval. If false, treats the trial indices
%                       like a list of blocked testing segments
%       .num_boots    : # bootstrap iterations to use
%       .distribution : distribution to use. See fitglm for options
%       .do_plot      : plot of directions for diagnostics, not for general
%                       use.
%
% OUTPUTS:
%   pdTable : calculated velocity PD table with CIs
%
% Written by Raeed Chowdhury. Updated Nov 2017.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function pdTable = getTDPDs(trial_data,params)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DEFAULT PARAMETERS
out_signals      =  [];
out_signal_names = {};
trial_idx        =  1:length(trial_data);
in_signals      = 'vel';
block_trials     =  false;
num_boots        =  1000;
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
dirArr = zeros(size(response_var,2),1);
dirCIArr = zeros(size(response_var,2),2);
moddepthArr = zeros(size(response_var,2),1);
moddepthCIArr = zeros(size(response_var,2),2);
pdTable = getNeuronTableStarter(trial_data,params);
for in_signal_idx = 1:size(in_signals,1)
    tab_append = table(dirArr,dirCIArr,moddepthArr,moddepthCIArr,...
                        'VariableNames',{[in_signals{in_signal_idx,1} 'PD'],[in_signals{in_signal_idx,1} 'PDCI'],[in_signals{in_signal_idx,1} 'Moddepth'],[in_signals{in_signal_idx,1} 'ModdepthCI']});
    pdTable = [pdTable tab_append];
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Calculate PD
bootfunc = @(data) fitglm(data(:,2:end),data(:,1),'Distribution',distribution);
if disp_times
    tic;
end
for uid = 1:size(response_var,2)
    if disp_times
        disp(['  Bootstrapping GLM PD computation(ET=',num2str(toc),'s).'])
    end
    %bootstrap for firing rates to get output parameters
    if block_trials
        % not implemented currently, look at evalModel for how block trials should be implemented
        error('getTDPDs:noBlockTrials','Block trials option is not implemented yet')
    else
        data_arr = [response_var(:,uid) input_var];
        % check if actually bootstrapping
        if num_boots>1
            boot_tuning = bootstrp(num_boots,@(data) {bootfunc(data)}, data_arr);
            boot_coef = cell2mat(cellfun(@(x) x.Coefficients.Estimate',boot_tuning,'uniformoutput',false));
        else
            % don't bootstrap
            boot_tuning = bootfunc(data_arr);
            boot_coef = boot_tuning.Coefficients.Estimate';
        end

        if size(boot_coef,2) ~= 1+size(in_signals,1)*2
            error('getTDPDs:moveCorrProblem','GLM doesn''t have correct number of inputs')
        end

        for in_signal_idx = 1:size(in_signals,1)
            move_corr = in_signals{in_signal_idx,1};

            dirs = atan2(boot_coef(:,1+in_signal_idx*2),boot_coef(:,in_signal_idx*2));
            %handle wrap around problems:
            centeredDirs=minusPi2Pi(dirs-circ_mean(dirs));

            if do_plot
                % plot for checking
                figure(12344)
                clf
                scatter(ones(size(dirs)),dirs,'ko')
                hold on
                scatter(1,dirArr(uid,:),'rx')
                scatter(2*ones(size(centeredDirs)),centeredDirs,'ko')
                scatter(2,0,'rx')
                scatter(ones(2,1),dirCIArr(uid,:),'gx')
                scatter(2*ones(2,1),dirCIArr(uid,:)-circ_mean(dirs),'gx')
                set(gca,'box','off','tickdir','out','xlim',[0 3])
            end

            pdTable.([move_corr 'PD'])(uid,:)=circ_mean(dirs);
            pdTable.([move_corr 'PDCI'])(uid,:)=prctile(centeredDirs,[2.5 97.5])+circ_mean(dirs);

            if(strcmpi(distribution,'normal'))
                % get moddepth
                moddepths = sqrt(sum(boot_coef(:,(2*in_signal_idx):(2*in_signal_idx+1)).^2,2));
                pdTable.([move_corr 'Moddepth'])(uid,:)= mean(moddepths);
                pdTable.([move_corr 'ModdepthCI'])(uid,:)= prctile(moddepths,[2.5 97.5]);
            else
                % moddepth is poorly defined for GLM context, but for this case, let's use sqrt(sum(squares))
                moddepths = sqrt(sum(boot_coef(:,(2*in_signal_idx):(2*in_signal_idx+1)).^2,2));
                pdTable.([move_corr 'Moddepth'])(uid,:)= mean(moddepths);
                pdTable.([move_corr 'ModdepthCI'])(uid,:)= prctile(moddepths,[2.5 97.5]);
            end
        end
    end
end

end%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
