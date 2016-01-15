%1. load cerebus file
%2. load colortracking file
%3. align times (based on led square wave)
%4. put kinect marker locations in handle coordinates
%   -if this is the first file from the day, find the rotation matrix and then use it
%   -if not, just use the rotation matrix found from another file from the day

%Output will be all the markers in handle coordinates, and in cerebus time
%% 1. LOAD CEREBUS FILE
folder = 'C:\Users\rhc307\Documents\Data\experiment_20151203_RWchaos_001\';
prefix = 'Chips_20151203_RWchaos_001';
bdf = get_nev_mat_data([folder prefix],6,'ignore_jumps');

%% 2. LOAD MOTION TRACKING FILE
load([folder 'markers_' prefix '.mat'])

%Note - this folder may be different than the one w/ the cerebus file?

%% 3. ALIGN TIMES (PUT THE MOTION TRACKING FILE IN CEREBUS TIME) 

%% 3a. Plot LED vals
figure; plot(times,led_vals,'r');
title('Kinect LED vals')

%% 3b. Enter kinect start time estimate

kinect_start_guess=7;

%% 3c. Align kinect led values with cerebus squarewave

plot_flag=1; %Whether to plot the match between the kinect LED and cerebus squarewaves
kinect_times  = match_squarewave_main( bdf, led_vals, times, kinect_start_guess, plot_flag);

%% 4. PUT KINECT MARKER LOCATIONS IN HANDLE COORDINATES

rotation_known=0; %Whether the rotation matrix is already known (from another file from that day)

%% 4a. Plot handle to determine some points to remove
%We want to remove the time points when the monkey has thrown away the
%handle, since then the hand won't be at the same position as the handle
if ~rotation_known
    figure; scatter(bdf.pos(1:10:end,2),bdf.pos(1:10:end,3))
%Note- this plot can be removed if the limits (below) are always the same
end
%% 4b. Set limits of handle points
%We'll remove times when the handle is outside these limits
if ~rotation_known
    x_lim_handle=[-10,10]; %x limits (min and max)
    y_lim_handle=[-55,-35]; %y limits (min and max)
end

%% 4c. Get Translation and Rotation

if ~rotation_known
    plot_flag=1;
    [ R, Tpre, Tpost, times_good, pos_h, colors_xy ] = get_translation_rotation( bdf, kinect_times, all_medians, x_lim_handle, y_lim_handle, plot_flag );
    %Save a file w/ T and R, so it can be used for other files from the
    %same day
    save([folder prefix '_kinect_rotation.mat'],'R','Tpre','Tpost')
else
    %Else load a file that has T and R
    load([folder prefix '_kinect_rotation.mat']);
end


%% 4d. Perform Translation and Rotation on the kinect data

if ~rotation_known
    plot_flag=1;
    [ kinect_pos ] = do_translation_rotation( all_medians, R, Tpre, Tpost, plot_flag, times_good, pos_h, colors_xy );
end

if rotation_known
    [ kinect_pos ] = do_translation_rotation( all_medians, R, Tpre, Tpost);
end
    
%% 5. SMOOTH OUT MARKERS

kinect_pos_smooth=NaN(size(kinect_pos));
for i=1:10
    for j=1:3
        temp=reshape(kinect_pos(i,j,:),[1,size(kinect_pos,3)]);
        kinect_pos_smooth(i,j,:)=medfilt1nan(temp,5);
    end
end

%% 5. FIND TIMES TO EXCLUDE (BECAUSE THE MONKEY THREW AWAY THE HANDLE)

%% 5a. Calculate the distances of the hand marker to the handle (and plot)
%This can be used to determine times when the monkey has thrown away the
%handle

n_times = size(all_medians,3);
k=reshape(kinect_pos_smooth(3,:,:),[3,n_times]);
h=bdf.pos(:,2:3);
h(:,3)=0;

err=NaN(1,n_times);
for i=1:n_times    
    err(i)=pdist2(k(1:2,i)',h(i,1:2));
end

figure; plot(kinect_times,err)
figure; scatter3(kinect_pos_smooth(3,1,:),kinect_pos_smooth(3,2,:),kinect_pos_smooth(3,3,:))
%This can be used in combination w/ the z-force

%% 6. PUT KINECT DATA INTO OPENSIM COORDINATES

% Robot coordinates:
% Origin at shoulder joint center of robot, x is to right, y is towards screen, z is up
% OpenSim coordinates:
% Origin at shoulder joint center (marker 9), x is towards screen, y is up, z is to right

% extract and clean up shoulder jc data
shoulder_pos = squeeze(kinect_pos_smooth(9,:,:))';
marker_loss_points = find(diff(isnan(shoulder_pos(:,1)))>0);
marker_reappear_points = find(diff(isnan(shoulder_pos(:,1)))<0);
if length(marker_loss_points)>length(marker_reappear_points)
    %Means that a marker was lost but never found again at end of file
    %append last index
    marker_reappear_points(end+1) = length(shoulder_pos);
elseif length(marker_loss_points)<length(marker_reappear_points)
    %Means that a marker was lost to start
    %Dont know what to do here other than throw a warning and toss first
    %reappearance
    marker_reappear_points(1) = [];
    warning('Shoulder position marker not found at start of file. May lead to unpredictable results')
end
for i=1:length(marker_loss_points)
    marker_loss = marker_loss_points(i);
    marker_reappear = marker_reappear_points(i);
    num_lost = marker_reappear-marker_loss;
    rep_coord = repmat(shoulder_pos(marker_loss,:),num_lost,1);
    shoulder_pos(marker_loss+1:marker_reappear,:) = rep_coord;
end

% Recenter all markers on shoulder position
rep_shoulder_pos = repmat(shoulder_pos,[1 1 11]);
rep_shoulder_pos = permute(rep_shoulder_pos,[3 2 1]);
kinect_pos_recenter = kinect_pos_smooth-rep_shoulder_pos;

% switch axes of coordinate frame
% x->z, y->x, z->y
kinect_pos_opensim = kinect_pos_recenter;
kinect_pos_opensim(:,1,:) = kinect_pos_recenter(:,2,:); % new x=old y
kinect_pos_opensim(:,2,:) = kinect_pos_recenter(:,3,:); % new y=old z
kinect_pos_opensim(:,3,:) = kinect_pos_recenter(:,1,:); % new z=old x

% change from cm to meters
kinect_pos_opensim = kinect_pos_opensim/100;

% clear variables for space
clear kinect_pos_recenter
clear rep_shoulder_pos
clear rep_coord
clear marker_loss_points
clear marker_reappear_points
clear marker_loss
clear marker_reappear
clear num_lost
clear shoulder_pos

%% 7. FIND BAD HAND FRAMES

% throw away all frames that have 1 or fewer hand markers
good_frame = true(size(kinect_pos_smooth,3),1);
for i=1:length(good_frame)
    if sum(isnan(kinect_pos_smooth(1:5,1,i)))>3
        good_frame(i) = false;
    end
end

%% 7. PUT KINECT DATA INTO BDF

%% 8. PUT KINECT MOTION TRACKING DATA INTO TRC FORMAT

% find meta data
frame_rate = 1/mean(diff(kinect_times));
num_markers = 10; % ONLY USED 10 MARKERS FOR CHIPS DATA
start_idx = find(kinect_times>=0,1,'first');
num_frames = length(kinect_times)-start_idx+1;
marker_names = {'Marker_1','Marker_2','Marker_3','Marker_4','Marker_5','Marker_6','Marker_7','Marker_8','Shoulder JC','Pronation Pt1'};

% open file and write header
fid = fopen([folder prefix '.trc'],'w');
fprintf(fid,['PathFileType\t4\tX/Y/Z\t' prefix '.trc\n']);
fprintf(fid,'DataRate\tCameraRate\tNumFrames\tNumMarkers\tUnits\tOrigDataRate\tOrigDataStartFrame\tOrigNumFrames\n');
fprintf(fid,'%5.2f\t%5.2f\t%d\t%d\tm\t%5.2f\t%d\t%d\n',[frame_rate frame_rate num_frames num_markers frame_rate 1 num_frames]);

% write out data header
fprintf(fid,'Frame#\tTime\t');
for i = 1:num_markers
    fprintf(fid,'%s\t\t\t',marker_names{i});
end
fprintf(fid,'\n');
fprintf(fid,'\t\t');
for i = 1:num_markers
    fprintf(fid,'X%d\tY%d\tZ%d\t',[i,i,i]);
end
fprintf(fid,'\n\n');

% write out data
for j=1:num_frames
    frame_idx = j-1+start_idx;
    if(good_frame(frame_idx))
        fprintf(fid,'%d\t%f\t',[j kinect_times(frame_idx)]);
        marker_pos = kinect_pos_opensim(1:num_markers,:,frame_idx);
        for i = 1:num_markers
            if isnan(marker_pos(i,1))
                fprintf(fid,'\t\t\t');
            else
                fprintf(fid,'%f\t%f\t%f\t',marker_pos(i,:));
            end
        end
        fprintf(fid,'\n');
    end
end

% close file
fclose(fid);