function [joint_angles, muscle_lengths, scaled_lengths, segment_angles_unc,segment_angles_con] = find_kinematics(base_leg,endpoint_positions, plotflag,joint_elast)

% base_angles in joint coordinates, not segment coordinates
base_angles = [pi/4 pi/2 pi/2];

% matrix to transform hip-centric segment angles into joint angles (offset
% by pi for knee and ankle), assuming row vector of segment angles (doing
% things in joint coordinates now, so not used)
joint_transform_for_inv = [1 0 0; 1 -1 0; 0 -1 1]';
num_positions = size(endpoint_positions,2);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Next, find angles coresponding to each endpoint position in normal case
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if(plotflag)
    figure
end
options = optimset('MaxFunEvals', 5000, 'MaxIter', 1000, 'Display', 'off', 'Algorithm', 'active-set');
x0 = base_angles';

muscle_lengths_unc = [];
joint_angles_unc = [];
start_angles_con = [];
segment_angles_unc = [];

for i = 1:num_positions
    my_ep = endpoint_positions(:,i);
    angles = fmincon(@(x) elastic_joint_cost(x,base_angles,joint_elast), x0, [],[],[],[],[],[],@(x) endpoint_constraint(x,my_ep,base_leg), options);
    start_angles_con = [start_angles_con angles];
%     joint_angles_unc = [joint_angles_unc; angles'*joint_transform];
    joint_angles_unc = [joint_angles_unc; angles'];
    segment_angles_unc = [segment_angles_unc; angles'/joint_transform_for_inv];
    mp = get_legpts(base_leg,angles'/joint_transform_for_inv);
    
    % plot leg if needed (only corners and center)
    if(plotflag)
        draw_bones(base_leg,angles'/joint_transform_for_inv,false,1);
        hold on
        if (isequal(my_ep,mp(:,base_leg.segment_idx(end,end))))
            plot(my_ep(1), my_ep(2), 'ro');
        else
            plot(my_ep(1), my_ep(2), 'bo');
        end
    end
    
    muscle_lengths_unc = [muscle_lengths_unc; get_musclelengths(base_leg,angles'/joint_transform_for_inv)];
end
if(plotflag)
    axis square
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

knee_constraint_angle = pi/2;

% % find vector from hip to ankle
% constrain_legpts = get_legpts(base_leg,[pi/2 0 0]);
% ankle_point = constrain_legpts(:,base_leg.segment_idx(3,2));
% [hipknee_orient,hipknee_len] = cart2pol(ankle_point(1),ankle_point(2));

options = optimset('MaxFunEvals', 5000, 'MaxIter', 1000, 'Display', 'off', 'Algorithm', 'active-set');
%x0 = [pi/4 pi/4];
x0 = base_angles';

muscle_lengths_con = [];
joint_angles_con = [];
segment_angles_con = [];

if(plotflag)
    figure;
end

for i = 1:num_positions
    my_ep = endpoint_positions(:,i);
%     [x,val,flag] = fminsearch(@mycostcon, x0, options);
    angles = fmincon(@(x) elastic_joint_cost(x,base_angles,joint_elast), start_angles_con(:,i) , [0 0 -1;0 0 1], [0; pi], [0 1 0], knee_constraint_angle,[],[],@(x) endpoint_constraint(x,my_ep,base_leg), options);
%     joint_angles_con = [joint_angles_con; angles'*joint_transform];
    joint_angles_con = [joint_angles_con; angles'];
    segment_angles_con = [segment_angles_con; angles'/joint_transform_for_inv];
    mp = get_legpts(base_leg,angles'/joint_transform_for_inv);
    
    % These were commented out
    if(plotflag)
        draw_bones(base_leg,angles'/joint_transform_for_inv,false,1);
        hold on
        if (isequal(my_ep,mp(:,base_leg.segment_idx(end,end))))
            plot(my_ep(1), my_ep(2), 'ro');
        else
            plot(my_ep(1), my_ep(2), 'bo');
        end
    end
    
    muscle_lengths_con = [muscle_lengths_con; get_musclelengths(base_leg,angles'/joint_transform_for_inv)];
end
if(plotflag)
    axis square
    % axis([-10 15 -20 5])
    title 'Constrained'
end

muscle_offset = min([muscle_lengths_unc;muscle_lengths_con]);
scaled_lengths_unc = muscle_lengths_unc - repmat(muscle_offset,num_positions,1);
scaled_lengths_con = muscle_lengths_con - repmat(muscle_offset,num_positions,1);

muscle_scale = max([scaled_lengths_unc;scaled_lengths_con]);
scaled_lengths_unc = scaled_lengths_unc ./ repmat(muscle_scale,num_positions,1);
scaled_lengths_con = scaled_lengths_con ./ repmat(muscle_scale,num_positions,1);

% make sure joint angles are between -pi and pi
while(~isempty(find(joint_angles_con<-pi | joint_angles_con>pi, 1)))
    joint_angles_con(joint_angles_con<-pi) = joint_angles_con(joint_angles_con<-pi)+2*pi;
    joint_angles_con(joint_angles_con> pi) = joint_angles_con(joint_angles_con> pi)-2*pi;
end

joint_angles = {joint_angles_unc; joint_angles_con};
muscle_lengths = {muscle_lengths_unc; muscle_lengths_con};
scaled_lengths = {scaled_lengths_unc; scaled_lengths_con};