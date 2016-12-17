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
num_secs = linspace(0.1,5,25);
for i = 1:length(num_secs)
    % DEPRECATED
    [num_tuned(i),~,pdChange(i),~,~] = run_hindlimb(neurons,num_secs(i),[1;1;1]);
end
toc
clear i