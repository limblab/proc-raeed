%% Set up
meta.lab=6;
meta.ranBy='Raeed';
meta.monkey='Chips';
meta.date='20170913';
meta.task='COactpas';
meta.filenum='001';
meta.array='LeftS1Area2';
meta.arrayAlias='area2';
meta.folder='C:\Users\rhc307\Projects\limblab\data-preproc\ForceKin\Chips\20170913\';

meta.colorTrackingFilename = [meta.monkey '_' meta.date '_' meta.task '_colorTracking_' meta.filenum];
meta.markersFilename = [meta.monkey '_' meta.date '_' meta.task '_markers_' meta.filenum];
meta.neuralFilename = [meta.monkey '_' meta.date '_' meta.task '_' meta.arrayAlias '_' meta.filenum];

altMeta = meta;
altMeta.array='RightCuneate';
altMeta.arrayAlias='cuneate';
altMeta.neuralFilename = [altMeta.monkey '_' altMeta.date '_' altMeta.task '_' altMeta.arrayAlias '_' altMeta.filenum];

if strcmp(meta.monkey,'Chips')
    meta.mapfile='C:\Users\rhc307\Projects\limblab\data-preproc\Meta\Mapfiles\Chips\left_S1\SN 6251-001455.cmp';
    clear altMeta
elseif strcmp(meta.monkey,'Han')
    warning('mapfiles not found for Han yet')
%     meta.mapfile='C:\Users\rhc307\Projects\limblab\data-preproc\Meta\Mapfiles\Chips\left_S1\SN 6251-001455.cmp';
%     altMeta.mapfile=???;
elseif strcmp(meta.monkey,'Lando')
    warning('mapfiles not found for Lando yet')
%     meta.mapfile='C:\Users\rhc307\Projects\limblab\data-preproc\Meta\Mapfiles\Chips\left_S1\SN 6251-001455.cmp';
%     altMeta.mapfile=???;
end

%% Load colorTracking file (and settings if desired)
fname_load=ls([meta.folder 'ColorTracking\' meta.colorTrackingFilename '*']);
load(deblank([meta.folder 'ColorTracking\' fname_load]))

%% Run color tracking script
color_tracker_4colors_script;

%% Save
if savefile
    fname_save=[main_dir '\ColorTracking\Markers\' meta.markersFilename '.mat'];
    save(fname_save,'all_medians','all_medians2','led_vals','times');
    
    if first_time
        fname_save_settings=[meta.folder '\ColorTracking\Markers\settings_' meta.monkey '_' meta.date];
        save(fname_save_settings,'red_elbow_dist_from_blue','red_blue_arm_dist_max',...
            'green_hand_dists_elbow','red_hand_dists_elbow','blue_hand_dists_elbow','yellow_hand_dists_elbow','green_separator',...
            'green_hand_dists_bluearm','red_hand_dists_bluearm','blue_hand_dists_bluearm','yellow_hand_dists_bluearm',...
            'green_hand_dists_redarm', 'red_hand_dists_redarm', 'blue_hand_dists_redarm','yellow_hand_dists_redarm',...
            'green_dist_min','red_keep','green_keep','blue_keep','yellow_keep','marker_inits');
    end
end

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clearvars -except meta altMeta

%% Load data into CDS file
% Make CDS files

cds = commonDataStructure();
cds.file2cds([meta.folder 'preCDS\Final\' meta.neuralFilename],...
    ['ranBy' meta.ranBy],['array' meta.array],['monkey' meta.monkey],meta.lab,'ignoreJumps',['task' meta.task],['mapFile' meta.mapfile]);

% also load second file if necessary
% cds.file2cds([altMeta.folder 'preCDS\Final\' altMeta.neuralFilename],...
%     ['ranBy' altMeta.ranBy],['array' altMeta.array],['monkey' altMeta.monkey],altMeta.lab,'ignoreJumps',['task' altMeta.task],['mapFile' altMeta.mapfile]);

%% Load marker file

marker_data = load([meta.folder 'ColorTracking\Markers\' meta.markersFilename '.mat']);

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