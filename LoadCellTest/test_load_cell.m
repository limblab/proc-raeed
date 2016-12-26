%% Load cds
addpath(genpath('C:\Users\rhc307\Projects\limblab\ClassyDataAnalysis'))

lab=6;
ranBy='ranByRaeed';
monkey='monkeyHan';
task='taskRW';
array='arrayLeftS1Area2';
folder='C:\Users\rhc307\Projects\limblab\data-raeed\TestData\20161226\';
% folder = '/home/raeed/Projects/limblab/data-raeed/MultiWorkspace/SplitWS/Han/20160322/area2/preCDS/';
fname='Loadcell_test_20161226_all_005';
% Make CDS files

cds = commonDataStructure();
cds.file2cds([folder fname],ranBy,array,monkey,lab,'ignoreJumps',task);

%%
figure
plot(cds.kin.x+cds.force.fx,cds.kin.y+cds.force.fy,'o')
hold on
plot(cds.kin.x,cds.kin.y,'r')
axis equal

%%
figure
plot(cds.force.fx,cds.force.fy,'o')