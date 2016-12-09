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
[temp1, temp2, temp3] = meshgrid(linspace(0.5,1.5,5)',linspace(0.5,1.5,5)',linspace(0.5,1.5,5)');
spring_list = [temp3(:) temp1(:) temp2(:)];
for i = 1:size(spring_list,1)
    [num_tuned_joint(i),~,pdChange_joint(i),~,~] = run_hindlimb(neurons,2,spring_list(i,:)');
end
toc
clear i