function [worldpoint,oiv_world] = get_legpts(legmodel,q)
% Get relevant points for leg in a particular configuration

%% Get world points
% prepend with implicit pelvis rotation
q_full = [0;q];
worldpoint = zeros(2,5);%origin of bod(i) in global coordinates
% get rotation matrices
cumrot = eye(2);
rots = zeros(2,2,4);
for index = 1:4
    rots(:,:,index) = [cos(q_full(index)) -sin(q_full(index)); sin(q_full(index)) cos(q_full(index))];
    cumrot = squeeze(rots(:,:,index))*cumrot;
    worldpoint(:,index+1,1) = worldpoint(:,index,1) + ...
        cumrot*legmodel.bodloc(:,index+1);
end

% recenter on hip center
worldpoint = worldpoint - repmat(legmodel.hipcenter,1,5);

%% Get axes of different frames
pelvis_axes = eye(2);
femur_axes = eye(2);
tibia_axes = eye(2);
foot_axes = eye(2);

pelvis_origin = worldpoint(:,1);
femur_origin = worldpoint(:,2);
tibia_origin = worldpoint(:,3);
foot_origin = worldpoint(:,4);

% pelvis axes is after first rotation
pelvis_axes = squeeze(rots(:,:,1))*pelvis_axes;

% femur axes is after 2 joints
for index = 1:2
    femur_axes = squeeze(rots(:,:,index))*femur_axes;
end

% tibia axes is after 3 joints
for index = 1:3
    tibia_axes = squeeze(rots(:,:,index))*tibia_axes;
end

% foot axes is after 4 joints
for index = 1:4
    foot_axes = squeeze(rots(:,:,index))*foot_axes;
end

%% Extract necessary muscles

muscles = legmodel.muscles;
oiv_world = cell(height(muscles),1);
lengths = zeros(1,height(muscles));

for musc_idx = 1:height(muscles)
    oiv = muscles.oiv{musc_idx};
    oivsegment = muscles.oivsegment{musc_idx};
    oiv_world{musc_idx} = oiv;
    for oiv_idx = 1:size(oiv,1)
        if strcmp(oivsegment{oiv_idx},'pelvis')
            oiv_world{musc_idx}(oiv_idx,:) = oiv(oiv_idx,:)*pelvis_axes'+pelvis_origin';
        elseif strcmp(oivsegment{oiv_idx},'femur')
            oiv_world{musc_idx}(oiv_idx,:) = oiv(oiv_idx,:)*femur_axes'+femur_origin';
        elseif strcmp(oivsegment{oiv_idx},'tibia')
            oiv_world{musc_idx}(oiv_idx,:) = oiv(oiv_idx,:)*tibia_axes'+tibia_origin';
        elseif strcmp(oivsegment{oiv_idx},'foot')
            oiv_world{musc_idx}(oiv_idx,:) = oiv(oiv_idx,:)*foot_axes'+foot_origin';
        else
            error('wrong frame')
        end
    end
end