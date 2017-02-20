function [num_tuned_pois,pdChange_pois,moddepthChange_pois] = poisson_sens(neurons,num_secs_pois)
%%%% Poisson sensitivity analysis
%% Set up path
% if(ispc)
%     homeFolder = 'C:\Users\rhc307\';
% else
%     homeFolder = '/home/raeed/';
% end
% % addpath(genpath('C:\Users\Raeed\Projects\limblab\ClassyDataAnalysis'))
% % addpath(genpath('/home/raeed/Projects/limblab/ClassyDataAnalysis'))
% addpath([homeFolder filesep 'Projects' filesep 'limblab' filesep 'proc-raeed' filesep 'Hindlimb' filesep])
% cd([homeFolder 'Dropbox' filesep 'Research' filesep 'cat hindlimb' filesep 'Data' filesep])
% % addpath('/home/raeed/Projects/limblab/proc-raeed/MultiWorkspace/lib/')
% % cd('/home/raeed/Projects/limblab/data-raeed/MultiWorkspace/SplitWS/Han/20160322/area2/')
% 
% clear homeFolder
% 
% %% load neurons
% load('sim_10000neuron_20151011.mat','neurons')

%% run hindlimb simulation
tic
% num_secs_pois = linspace(0.1,5,25);
for i = 1:length(num_secs_pois)
    % DEPRECATED
    [tuning_elast_pois,tuning_fixed_pois] = run_hindlimb(neurons,num_secs_pois(i),[1;1;1]);
    
    isTuned_pois = tuning_elast_pois.isTuned & tuning_fixed_pois.isTuned;

    coef_elast_pois = tuning_elast_pois.coef(isTuned_pois,:)';
    coef_fixed_pois = tuning_fixed_pois.coef(isTuned_pois,:)';

    PD_elast = atan2(coef_elast_pois(3,:),coef_elast_pois(2,:));
    PD_fixed = atan2(coef_fixed_pois(3,:),coef_fixed_pois(2,:));
    moddepth_elast = sqrt(sum(coef_elast_pois(2:3,:).^2));
    moddepth_fixed = sqrt(sum(coef_fixed_pois(2:3,:).^2));
    
    num_tuned_pois(i) = sum(isTuned_pois);
    pdChange_pois(i) = median(acosd(cos(PD_fixed-PD_elast)));
    moddepthChange_pois(i) = median(moddepth_fixed./moddepth_elast);
end
toc
clear i