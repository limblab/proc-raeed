%% Load cds

lab=6;
ranBy='ranByRaeed';
monkey='monkeyHan';
task='taskRW';
array='arrayLeftS1Area2';
folder='C:\Users\rhc307\Projects\limblab\data-preproc\Misc\LoadCell\20180326\';
fname='LoadCell_20180326_still';
% Make CDS files

cds = commonDataStructure();
cds.file2cds([folder fname],ranBy,array,monkey,lab,'ignoreJumps',task,'useAbsoluteStillThresh');
% cds.file2cds([folder fname],ranBy,array,monkey,lab,'ignoreJumps',task,'getLoadCellOffsets','useAbsoluteStillThresh');

%%
figure
plot(cds.kin.x+cds.force.fx,cds.kin.y+cds.force.fy,'o')
hold on
plot(cds.kin.x,cds.kin.y,'r')
axis equal

%%
figure
plot(cds.force.fx,cds.force.fy,'o')
axis equal

%% 
figure
plot(cds.force.t,cds.force.fy)
