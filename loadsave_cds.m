%% Load colorTracking file
main_dir='C:\Users\rhc307\Projects\limblab\data-preproc\ForceKin\Chips\20170913';
monkey='Chips';
date='20170913'; %mo-day-yr
exp='COactpas';
num='001';
% file_name = 'Han_20170206_CObumpcurl_adaptation_colorTracking_003';
file_name = [monkey '_' date '_' exp '_colorTracking_' num];

% Load ColorTracking File and Settings
fname_load=ls([main_dir '/ColorTracking/' file_name '*']);
load(deblank([main_dir '/ColorTracking/' fname_load]))

%% Run color tracking script
color_tracker_4colors_script;

%% Save
if savefile
    fname_save=[main_dir '\ColorTracking\Markers\markers_' monkey '_' date '_' exp '_' num];
    save(fname_save,'all_medians','all_medians2','led_vals','times');
    
    if first_time
        fname_save_settings=[main_dir '\ColorTracking\Markers\settings_' monkey '_' date];
        save(fname_save_settings,'red_elbow_dist_from_blue','red_blue_arm_dist_max',...
            'green_hand_dists_elbow','red_hand_dists_elbow','blue_hand_dists_elbow','yellow_hand_dists_elbow','green_separator',...
            'green_hand_dists_bluearm','red_hand_dists_bluearm','blue_hand_dists_bluearm','yellow_hand_dists_bluearm',...
            'green_hand_dists_redarm', 'red_hand_dists_redarm', 'blue_hand_dists_redarm','yellow_hand_dists_redarm',...
            'green_dist_min','red_keep','green_keep','blue_keep','yellow_keep','marker_inits');
    end
end

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear
%% Load data into CDS file

meta.lab=6;
meta.ranBy='ranByRaeed';
meta.monkey='monkeyChips';
meta.task='taskCObump';
meta.array='arrayLeftS1Area2';
meta.folder='C:\Users\rhc307\Projects\limblab\data-preproc\ForceKin\Chips\20170913\';
meta.fname='Chips_20170913_COactpas_area2_001';
meta.mapfile='mapFileC:\Users\rhc307\Projects\limblab\data-preproc\Meta\Mapfiles\Chips\left_S1\SN 6251-001455.cmp';

% Make CDS files

cds = commonDataStructure();
cds.file2cds([meta.folder 'preCDS\' meta.fname],meta.ranBy,meta.array,meta.monkey,meta.lab,'ignoreJumps',meta.task,meta.mapfile);
% also load second EMG file if necessary

%% Load marker file

marker_data = load([meta.folder 'ColorTracking\Markers\' 'markers_' meta.fname '.mat']);

%% Get TRC

% go to getTRCfromMarkers and run from there for now.
affine_xform = getTRCfromMarkers(cds,marker_data,[meta.folder 'OpenSim\']);

%% Do openSim stuff and save analysis results to analysis folder

% do this in opensim for now

%% Add kinematic information to CDS

% load joint information
cds.loadOpenSimData([meta.folder 'OpenSim\Analysis\'],'joint_ang')

% load joint velocities
cds.loadOpenSimData([meta.folder 'OpenSim\Analysis\'],'joint_vel')

% load joint moments
cds.loadOpenSimData([meta.folder 'OpenSim\Analysis\'],'joint_dyn')

% load muscle information
cds.loadOpenSimData([meta.folder 'OpenSim\Analysis\'],'muscle_len')

% load muscle velocities
cds.loadOpenSimData([meta.folder 'OpenSim\Analysis\'],'muscle_vel')

%% Save CDS

save([meta.folder 'CDS\' meta.fname '_CDS.mat'],'cds','-v7.3')