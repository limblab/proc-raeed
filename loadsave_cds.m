%% Set up
meta.lab=6;
meta.ranBy='Raeed';
meta.monkey='Chips';
meta.date='20170913';
meta.task='COactpas'; % for the loading of cds
meta.taskAlias={'COactpas_001'}; % for the filename (cell array list for files to load and save)
meta.array='LeftS1Area2'; % for the loading of cds
meta.arrayAlias='area2'; % for the filename
meta.folder='C:\Users\rhc307\Projects\limblab\data-preproc\ForceKin\Chips\20170913\';

meta.neuralPrefix = [meta.monkey '_' meta.date '_' meta.arrayAlias];

if strcmp(meta.monkey,'Chips')
    meta.mapfile='C:\Users\rhc307\Projects\limblab\data-preproc\Meta\Mapfiles\Chips\left_S1\SN 6251-001455.cmp';
elseif strcmp(meta.monkey,'Han')
    warning('mapfiles not found for Han yet')
%     meta.mapfile='C:\Users\rhc307\Projects\limblab\data-preproc\Meta\Mapfiles\Chips\left_S1\SN 6251-001455.cmp';
    altMeta = meta;
    altMeta.array='';
    altMeta.arrayAlias='EMGextra';
    altMeta.neuralPrefix = [altMeta.monkey '_' altMeta.date '_' altMeta.arrayAlias];
%     altMeta.mapfile=???;
elseif strcmp(meta.monkey,'Lando')
    warning('mapfiles not found for Lando yet')
%     meta.mapfile='C:\Users\rhc307\Projects\limblab\data-preproc\Meta\Mapfiles\Chips\left_S1\SN 6251-001455.cmp';
    altMeta = meta;
    altMeta.array='RightCuneate';
    altMeta.arrayAlias='cuneate';
    altMeta.neuralPrefix = [altMeta.monkey '_' altMeta.date '_' altMeta.arrayAlias];
%     altMeta.mapfile=???;
end

%% Set up folder structure
if ~exist(fullfile(meta.folder,'preCDS'),'dir')
    mkdir(fullfile(meta.folder,'preCDS'))
    movefile(fullfile(meta.folder,[meta.neuralPrefix '*']),fullfile(meta.folder,'preCDS'))
    if exist('altMeta','var')
        movefile(fullfile(meta.folder,[altMeta.neuralPrefix '*']),fullfile(meta.folder,'preCDS'))
    end
end
if ~exist(fullfile(meta.folder,'preCDS','merging'),'dir')
    mkdir(fullfile(meta.folder,'preCDS','merging'))
    copyfile(fullfile(meta.folder,'preCDS',[meta.neuralPrefix '*.nev']),fullfile(meta.folder,'preCDS','merging'))
    if exist('altMeta','var')
        copyfile(fullfile(meta.folder,'preCDS',[altMeta.neuralPrefix '*.nev']),fullfile(meta.folder,'preCDS','merging'))
    end
end
if ~exist(fullfile(meta.folder,'preCDS','Final'),'dir')
    mkdir(fullfile(meta.folder,'preCDS','Final'))
    movefile(fullfile(meta.folder,'preCDS',[meta.neuralPrefix '*.n*']),fullfile(meta.folder,'preCDS','Final'))
    if exist('altMeta','var')
        movefile(fullfile(meta.folder,[altMeta.neuralPrefix '*.n*']),fullfile(meta.folder,'preCDS','Final'))
    end
end
if ~exist(fullfile(meta.folder,'ColorTracking'),'dir')
    mkdir(fullfile(meta.folder,'ColorTracking'))
    movefile(fullfile(meta.folder,'*_colorTracking_*.mat'),fullfile(meta.folder,'ColorTracking'))
end
if ~exist(fullfile(meta.folder,'ColorTracking','Markers'),'dir')
    mkdir(fullfile(meta.folder,'ColorTracking','Markers'))
end
if ~exist(fullfile(meta.folder,'OpenSim'),'dir')
    mkdir(fullfile(meta.folder,'OpenSim'))
end
if ~exist(fullfile(meta.folder,'CDS'),'dir')
    mkdir(fullfile(meta.folder,'CDS'))
end
if ~exist(fullfile(meta.folder,'TD'),'dir')
    mkdir(fullfile(meta.folder,'TD'))
end

%% Merge and strip files for spike sorting
% Run processSpikesForSorting for the first time to combine spike data from
% all files with a name starting with file_prefix.
processSpikesForSorting(fullfile(meta.folder,'preCDS','merging'),meta.neuralPrefix);
if exist('altMeta','var') && ~isempty(altMeta.array)
    processSpikesForSorting(fullfile(altMeta.folder,'preCDS','merging'),altMeta.neuralPrefix);
end

% Now sort in Offline Sorter!

%% Load colorTracking file (and settings if desired) -- NOTE: Can do this simultaneously with sorting, since it takes some time
for fileIdx = 1:length(meta.taskAlias)
    colorTrackingFilename = [meta.monkey '_' meta.date '_colorTracking_' meta.taskAlias{fileIdx}];

    fname_load=ls([meta.folder 'ColorTracking\' colorTrackingFilename '*']);
    load(deblank([meta.folder 'ColorTracking\' fname_load]))

    % Run color tracking script
    color_tracker_4colors_script;

    % Save
    markersFilename = [meta.monkey '_' meta.date '_markers_' meta.taskAlias{fileIdx}];
    fname_save=[meta.folder 'ColorTracking\Markers\' markersFilename '.mat'];
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

%% Split files and move to Final folder before loading
processSpikesForSorting(fullfile(meta.folder,'preCDS','merging'),meta.neuralPrefix);
if exist('altMeta','var') && ~isempty(altMeta.array)
    processSpikesForSorting(fullfile(altMeta.folder,'preCDS','merging'),altMeta.neuralPrefix);
end

% copy into final folder
for fileIdx = 1:length(meta.taskAlias)
    copyfile([meta.folder 'preCDS\merging\' meta.neuralPrefix '_' meta.taskAlias{fileIdx} '.mat'],...
        [meta.folder 'preCDS\Final\']);
    if exist('altMeta','var') && ~isempty(altMeta.array)
        processSpikesForSorting(fullfile(altMeta.folder,'preCDS','merging'),altMeta.neuralPrefix);
    end
end

%% Load data into CDS file
% Make CDS files
for fileIdx = 1:length(meta.taskAlias)
    cds{fileIdx} = commonDataStructure();
    cds{fileIdx}.file2cds([meta.folder 'preCDS\Final\' meta.neuralPrefix '_' meta.taskAlias{fileIdx}],...
        ['ranBy' meta.ranBy],['array' meta.array],['monkey' meta.monkey],meta.lab,'ignoreJumps',['task' meta.task],['mapFile' meta.mapfile]);

    % also load second file if necessary
    if exist('altMeta','var')
        cds{fileIdx}.file2cds([altMeta.folder 'preCDS\Final\' altMeta.neuralPrefix '_' altMeta.taskAlias{fileIdx}],...
            ['ranBy' altMeta.ranBy],['array' altMeta.array],['monkey' altMeta.monkey],altMeta.lab,'ignoreJumps',['task' altMeta.task],['mapFile' altMeta.mapfile]);
    end
end

%% Load marker file and create TRC
for fileIdx = 1:length(meta.taskAlias)
    markersFilename = [meta.monkey '_' meta.date '_markers_' meta.taskAlias{fileIdx}];
    marker_data = load([meta.folder 'ColorTracking\Markers\' markersFilename '.mat']);
    affine_xform = getTRCfromMarkers(cds{fileIdx},marker_data,[meta.folder 'OpenSim\']);
end

%% Do openSim stuff and save analysis results to analysis folder

% do this in opensim for now

%% Add kinematic information to CDS
for fileIdx = 1:length(meta.taskAlias)
    % load joint information
    cds{fileIdx}.loadOpenSimData([meta.folder 'OpenSim\Analysis\'],'joint_ang')

    % load joint velocities
    cds{fileIdx}.loadOpenSimData([meta.folder 'OpenSim\Analysis\'],'joint_vel')

    % load joint moments
    cds{fileIdx}.loadOpenSimData([meta.folder 'OpenSim\Analysis\'],'joint_dyn')

    % load muscle information
    cds{fileIdx}.loadOpenSimData([meta.folder 'OpenSim\Analysis\'],'muscle_len')

    % load muscle velocities
    cds{fileIdx}.loadOpenSimData([meta.folder 'OpenSim\Analysis\'],'muscle_vel')
end

%% Save CDS
save([meta.folder 'CDS\' meta.neuralPrefix '_CDS.mat'],'cds','-v7.3')

%% Save TD
params.array_alias = {'LeftS1Area2','S1'};
% params.exclude_units = [255];
params.event_list = {'ctrHoldBump';'bumpTime';'bumpDir';'ctrHold'};
params.trial_results = {'R','A','F','I'};
td_meta = struct('task',meta.task);
params.meta = td_meta;
trial_data = parseFileByTrial(cds{1},params);

% td_meta = struct('task',meta.task,'epoch','BL');
% params.meta = td_meta;
% trial_data_BL = parseFileByTrial(cds{1},params);
% params.meta.epoch = 'AD';
% trial_data_AD = parseFileByTrial(cds{2},params);
% params.meta.epoch = 'WO';
% trial_data_WO = parseFileByTrial(cds{3},params);
% 
% trial_data = cat(2,trial_data_BL,trial_data_AD,trial_data_WO);

save([meta.folder 'TD\' meta.monkey '_' meta.date '_TD.mat'],'trial_data','-v7.3')