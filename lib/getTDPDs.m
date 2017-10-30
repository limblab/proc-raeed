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
%                         DEFAULT: [1,length(trial_data]
%       .move_corr    : (string) name of behavior correlate for PD
%                           'vel' : velocity of handle
%                           'acc' : acceleration of handle
%                           'force'  : force on handle
%       .block_trials : (NOT IMPLEMENTED) if true, takes input of trial indices and pools
%                       them together for a single eval. If false, treats the trial indices
%                       like a list of blocked testing segments
%       .num_boots    : # bootstrap iterations to use (if <2, doesn't bootstrap)
%       .distribution : distribution to use. See fitglm for options
%       .do_plot      : plot of directions for diagnostics, not for general
%                       use.
%
% OUTPUTS:
%   pdTable : calculated velocity PD table with CIs
%
% Written by Raeed Chowdhury. Updated Jul 2017.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function pdTable = getTDPDs(trial_data,params)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DEFAULT PARAMETERS
out_signals      =  [];
out_signal_names = {};
trial_idx        =  [1,length(trial_data)];
move_corr      =  '';
block_trials     =  false;
num_boots        =  1000;
distribution = 'Poisson';
do_plot = false;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Some undocumented parameters
td_fn_prefix     =  '';    % prefix for fieldname
if nargin > 1, assignParams(who,params); end % overwrite parameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
possible_corrs = {'vel','acc','force'};
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Process inputs
if isempty(out_signals), error('Need to provide output signal'); end
if isempty(move_corr), error('Must provide movement correlate.'); end
if ~any(ismember(move_corr,possible_corrs)), error('Correlate not recognized.'); end
out_signals = check_signals(trial_data(1),out_signals);
response_var = get_vars(trial_data,out_signals);

if numel(unique(cat(1,{trial_data.monkey}))) > 1
    error('More than one monkey in trial data')
end
monkey = repmat({trial_data(1).monkey},size(response_var,2),1);
if numel(unique(cat(1,{trial_data.date}))) > 1
    date = cell(size(response_var,2),1);
    warning('More than one date in trial data')
else
    date = repmat({trial_data(1).date},size(response_var,2),1);
end
if numel(unique(cat(1,{trial_data.task}))) > 1
    task = cell(size(response_var,2),1);
    warning('More than one task in trial data')
else
    task = repmat({trial_data(1).task},size(response_var,2),1);
end

out_signal_names = reshape(out_signal_names,size(response_var,2),[]);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Calculate PD
bootfunc = @(data) fitglm(data(:,2:end),data(:,1),'Distribution',distribution);
tic;
for uid = 1:size(response_var,2)
    disp(['  Bootstrapping GLM PD computation(ET=',num2str(toc),'s).'])
    %bootstrap for firing rates to get output parameters
    if block_trials
        % not implemented currently, look at evalModel for how block trials should be implemented
        error('getTDPDs:noBlockTrials','Block trials option is not implemented yet')
    else
        data_arr = [response_var(:,uid) cat(1,trial_data.(move_corr))];
        boot_tuning = bootstrp(num_boots,@(data) {bootfunc(data)}, data_arr);
        boot_coef = cell2mat(cellfun(@(x) x.Coefficients.Estimate',boot_tuning,'uniformoutput',false));

        if size(boot_coef,2) ~= 3
            error('getTDPDs:moveCorrProblem','GLM doesn''t have correct number of inputs')
        end

        dirs = atan2(boot_coef(:,3),boot_coef(:,2));
        %handle wrap around problems:
        centeredDirs=minusPi2Pi(dirs-circ_mean(dirs));
        dirArr(uid,:)=circ_mean(dirs);
        dirCIArr(uid,:)=prctile(centeredDirs,[2.5 97.5])+circ_mean(dirs);

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

        if(strcmpi(distribution,'normal'))
            % get moddepth
            moddepths = sqrt(sum(boot_coef(:,2:3).^2,2));
            moddepthArr(uid,:) = mean(moddepths);
            moddepthCIArr(uid,:) = prctile(moddepths,[2.5 97.5]);
        else
            moddepthArr(uid,:) = -1;
            moddepthCIArr(uid,:) = [-1 -1];
        end
    end
end

% package output
pdTable = table(monkey,date,task,out_signal_names,dirArr,dirCIArr,moddepthArr,moddepthCIArr,...
        'VariableNames',{'monkey','date','task','signalID',[move_corr 'Dir'],[move_corr 'DirCI'],[move_corr 'Moddepth'],[move_corr 'ModdepthCI']});



end%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
