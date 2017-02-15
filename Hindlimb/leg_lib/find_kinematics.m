function [joint_angles, muscle_lengths, scaled_lengths, segment_angles_unc,segment_angles_con] = find_kinematics(legmodel,endpoint_positions, plotflag,joint_elast)

% base_angles in joint coordinates, not segment coordinates
base_q = legmodel.default_angles;

% matrix to transform hip-centric segment angles into joint angles (offset
% by pi for knee and ankle), assuming row vector of segment angles (doing
% things in joint coordinates now, so not used)
% joint_transform_for_inv = [1 0 0; 1 -1 0; 0 -1 1]';
num_positions = size(endpoint_positions,2);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Next, find angles coresponding to each endpoint position in normal case
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if(plotflag)
    figure
end
options = optimset('MaxFunEvals', 5000, 'MaxIter', 1000, 'Display', 'off', 'Algorithm', 'active-set');

muscle_lengths_unc = [];
joint_angles_unc = [];
start_angles_con = [];
segment_angles_unc = [];

for i = 1:num_positions
    my_ep = endpoint_positions(:,i);
    q = fmincon(@(x) elastic_joint_cost(x,base_q,joint_elast), base_q, [0 0 -1;0 0 1;0 1 0;0 -1 0], [-5/180*pi; 120/180*pi; 0; 150/180*pi],[],[],[],[],@(x) endpoint_constraint(x,my_ep,legmodel), options);
%     q = fmincon(@(x) elastic_joint_cost(x,base_q,joint_elast), base_q, [], [],[],[],[],[],@(x) endpoint_constraint(x,my_ep,legmodel), options);
    start_angles_con = [start_angles_con q];
%     joint_angles_unc = [joint_angles_unc; angles'*joint_transform];
    joint_angles_unc = [joint_angles_unc; q'];
%     segment_angles_unc = [segment_angles_unc; angles'/joint_transform_for_inv];
%     mp = get_legpts(legmodel,angles'/joint_transform_for_inv);
    
    % plot leg if needed (only corners and center)
    if(plotflag)
        draw_hindlimb(legmodel,q,false);
        hold on
        if (isequal(my_ep,get_toepoint(legmodel,q)))
            plot(my_ep(1), my_ep(2), 'ro');
        else
            plot(my_ep(1), my_ep(2), 'bo');
        end
    end
    
%     waitforbuttonpress;
    
    muscle_lengths_unc = [muscle_lengths_unc; get_musclelengths(legmodel,q)];
end
if(plotflag)
    axis equal
    % axis([-10 15 -20 5])
    title 'Unconstrained'
end

% make sure joint angles are between -pi and pi
while(~isempty(find(joint_angles_unc<-pi | joint_angles_unc>pi, 1)))
    joint_angles_unc(joint_angles_unc<-pi) = joint_angles_unc(joint_angles_unc<-pi)+2*pi;
    joint_angles_unc(joint_angles_unc> pi) = joint_angles_unc(joint_angles_unc> pi)-2*pi;
end





%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Next, find angles coresponding to each endpoint position in constrained case
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

knee_constraint_angle = legmodel.default_angles(2);
% knee_constraint_angle = -pi/2;

% find vector from hip to ankle
% constrain_legpts = get_legpts(base_leg,[0 -knee_constraint_angle 0]);
% ankle_point = constrain_legpts(:,base_leg.segment_idx(2,2));
% [hipknee_orient,hipknee_len] = cart2pol(ankle_point(1),ankle_point(2));
% foot_len = sqrt(sum((constrain_legpts(:,base_leg.segment_idx(3,2))-constrain_legpts(:,base_leg.segment_idx(3,1))).^2));

options = optimset('MaxFunEvals', 5000, 'MaxIter', 1000, 'Display', 'off', 'Algorithm', 'active-set');
%x0 = [pi/4 pi/4];

muscle_lengths_con = [];
joint_angles_con = [];
segment_angles_con = [];

if(plotflag)
    figure;
end

for i = 1:num_positions
    my_ep = endpoint_positions(:,i);
%     [x,val,flag] = fminsearch(@mycostcon, x0, options);
%     angles = fmincon(@(x) elastic_joint_cost(x,base_angles,joint_elast), start_angles_con(:,i) , [0 0 -1;0 0 1], [0; pi], [0 1 0], knee_constraint_angle,[],[],@(x) endpoint_constraint(x,my_ep,base_leg), options);
    q = fmincon(@(x) elastic_joint_cost(x,base_q,[1;1;1]), base_q , [0 0 -1;0 0 1], [-5/180*pi; 120/180*pi], [0 1 0], knee_constraint_angle,[],[],@(x) endpoint_constraint(x,my_ep,legmodel), options);
%     q = fmincon(@(x) elastic_joint_cost(x,base_q,[1;1;1]), base_q , [], [], [0 1 0], knee_constraint_angle,[],[],@(x) endpoint_constraint(x,my_ep,legmodel), options);
    joint_angles_con = [joint_angles_con; q'];
%     segment_angles_con = [segment_angles_con; q'/joint_transform_for_inv];
%     mp = get_legpts(legmodel,q'/joint_transform_for_inv);
    
    % Do some 2-link inverse kinematics
%     D = (sum(my_ep.^2)-hipknee_len^2-foot_len^2)/(2*hipknee_len*foot_len);
%     theta2 = atan2(-sqrt(1-D^2),D);
%     theta1 = atan2(my_ep(2),my_ep(1)) - atan2(foot_len*sin(theta2),(hipknee_len+foot_len*cos(theta2)));
%     
%     % convert to segment angles
%     hip_angle = theta1 + hipknee_orient;
%     knee_angle = hip_angle - knee_constraint_angle;
%     ankle_angle = theta2+theta1-pi/2;
%     seg_angles = [hip_angle;knee_angle;ankle_angle];
%     segment_angles_con = [segment_angles_con;seg_angles'];
%     
%     % convert to joint angles
%     angles = (seg_angles'*joint_transform_for_inv)';
%     joint_angles_con = [joint_angles_con; angles'];
    
    % These were commented out
    if(plotflag)
        draw_hindlimb(legmodel,q,false);
        hold on
        if (isequal(my_ep,get_toepoint(legmodel,q)))
            plot(my_ep(1), my_ep(2), 'ro');
        else
            plot(my_ep(1), my_ep(2), 'bo');
        end
    end
    
%     waitforbuttonpress;
    
    muscle_lengths_con = [muscle_lengths_con; get_musclelengths(legmodel,q)];
end
if(plotflag)
    axis equal
    % axis([-10 15 -20 5])
    title 'Constrained'
end

%% scale muscle lengths
muscle_offset = min([muscle_lengths_unc;muscle_lengths_con]);
scaled_lengths_unc = muscle_lengths_unc - repmat(muscle_offset,num_positions,1);
scaled_lengths_con = muscle_lengths_con - repmat(muscle_offset,num_positions,1);

muscle_scale = max([scaled_lengths_unc;scaled_lengths_con]);
scaled_lengths_unc = scaled_lengths_unc ./ repmat(muscle_scale,num_positions,1);
scaled_lengths_con = scaled_lengths_con ./ repmat(muscle_scale,num_positions,1);

%% make sure joint angles are between -pi and pi
while(~isempty(find(joint_angles_con<-pi | joint_angles_con>pi, 1)))
    joint_angles_con(joint_angles_con<-pi) = joint_angles_con(joint_angles_con<-pi)+2*pi;
    joint_angles_con(joint_angles_con> pi) = joint_angles_con(joint_angles_con> pi)-2*pi;
end

%% outputs
joint_angles = {joint_angles_unc; joint_angles_con};
muscle_lengths = {muscle_lengths_unc; muscle_lengths_con};
scaled_lengths = {scaled_lengths_unc; scaled_lengths_con};