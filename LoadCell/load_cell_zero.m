%%

lab=6;
task='taskRW';
folder='C:\Users\rhc307\Projects\limblab\data-preproc\Misc\LoadCell\20171218\';
fname='Loadcell_20171218_still';
% Make CDS files

cds = commonDataStructure();
cds.file2cds([folder fname],lab,'ignoreJumps',task,'getLoadCellOffsets','useAbsoluteStillThresh');