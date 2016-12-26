%% Load cds
addpath(genpath('C:\Users\Raeed\Projects\limblab\ClassyDataAnalysis'))

lab=6;
ranBy='ranByRaeed';
monkey='monkeyHan';
task='taskRW';
array='arrayLeftS1Area2';
folder='C:\Users\Raeed\Projects\limblab\data-raeed\Test data\20161225\';
% folder = '/home/raeed/Projects/limblab/data-raeed/MultiWorkspace/SplitWS/Han/20160322/area2/preCDS/';
fname='Loadcell_test_down_002';
% Make CDS files

cds = commonDataStructure();
cds.file2cds([folder fname],ranBy,array,monkey,lab,'ignoreJumps',task);

figure
plot(cds.kin.x+cds.force.fx,cds.kin.y+cds.force.fy,'o')
hold on
plot(cds.kin.x,cds.kin.y,'r')
axis equal