% try joint angle simulation
%% load old file
load('C:\Users\Raeed\Dropbox\Research\cat hindlimb\Data\sim_10000neuron_20151011.mat');

%% set up neurons for joints
neurons = random('Normal',0,1,10000,3);

max_joint_angles = max([joint_angles_unc;joint_angles_con]);
min_joint_angles = min([joint_angles_unc;joint_angles_con]);
range_joint_angles = max_joint_angles-min_joint_angles;

min_rep = repmat(min_joint_angles,num_positions,1);
range_rep = repmat(range_joint_angles,num_positions,1);

scaled_joint_angles_unc = (joint_angles_unc-min_rep)./range_rep;
scaled_joint_angles_con = (joint_angles_con-min_rep)./range_rep;

clear min_rep
clear range_rep

num_sec = 4;
activity_unc = get_activity(neurons,scaled_joint_angles_unc,num_sec);
activity_con = get_activity(neurons,scaled_joint_angles_con,num_sec);