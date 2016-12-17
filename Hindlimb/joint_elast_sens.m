%%%% Poisson sensitivity analysis
%% Set up path
if(ispc)
    homeFolder = 'C:\Users\rhc307\';
else
    homeFolder = '/home/raeed/';
end
% addpath(genpath('C:\Users\Raeed\Projects\limblab\ClassyDataAnalysis'))
% addpath(genpath('/home/raeed/Projects/limblab/ClassyDataAnalysis'))
addpath([homeFolder filesep 'Projects' filesep 'limblab' filesep 'proc-raeed' filesep 'Hindlimb' filesep])
cd([homeFolder 'Dropbox' filesep 'Research' filesep 'cat hindlimb' filesep 'Data' filesep])
% addpath('/home/raeed/Projects/limblab/proc-raeed/MultiWorkspace/lib/')
% cd('/home/raeed/Projects/limblab/data-raeed/MultiWorkspace/SplitWS/Han/20160322/area2/')

clear homeFolder

%% load neurons
load('sim_10000neuron_20151011.mat','neurons')

%% run hindlimb simulation
tic
[temp1, temp2, temp3] = meshgrid(linspace(0.75,1.25,5)',linspace(0.75,1.25,5)',linspace(0.75,1.25,5)');
spring_list = [temp3(:) temp1(:) temp2(:)];
num_tuned_spring = zeros(1,length(spring_list));
pdChange_spring = zeros(1,length(spring_list));
moddepthChange_spring = zeros(1,length(spring_list));
for i = 1:size(spring_list,1)
    [tuning_elast_spring,tuning_fixed_spring] = run_hindlimb(neurons,2,spring_list(i,:)');
    
    isTuned_spring = tuning_elast_spring.isTuned & tuning_fixed_spring.isTuned;

    coef_elast_spring = tuning_elast_spring.coef(isTuned_spring,:)';
    coef_fixed_spring = tuning_fixed_spring.coef(isTuned_spring,:)';

    base_leg = get_baseleg;
    PD_elast = atan2(coef_elast_spring(3,:),coef_elast_spring(2,:));
    PD_fixed = atan2(coef_fixed_spring(3,:),coef_fixed_spring(2,:));
    moddepth_elast = sqrt(sum(coef_elast_spring(2:3,:).^2));
    moddepth_fixed = sqrt(sum(coef_fixed_spring(2:3,:).^2));
    
    num_tuned_spring(i) = sum(isTuned_spring);
    pdChange_spring(i) = median(acosd(cos(PD_fixed-PD_elast)));
    moddepthChange_spring(i) = median(moddepth_fixed./moddepth_elast);
end
toc
clear i
clear tuning_*
clear isTuned*
clear coef*
clear temp*
clear spring_list
clear moddepth_*
clear PD_*
