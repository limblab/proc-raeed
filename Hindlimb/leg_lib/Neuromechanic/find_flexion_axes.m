%% find flexion axes for 2D model
% load ncmb
nmcb = read_nmcb('basicCatHindlimb_201201.nmcb');

% neutral joint configuration
q = [0 0 0 -60 -14 0 -82 0 -78 0]'*pi/180;

% intersection plane for finding flexion axis positions
zplane = 0.01;

% use drawmodel to get world points
% [~,worldpoint,endpoint] = drawmodel(nmcb,q);

nbod = length(nmcb.bod);

%NMCB structure allows multiple axes connecting 2 bodies, which really
%complicates calculations.  We're going to convert that to a series of
%segments connected by single rotational degrees of freedom by replacing
%single bodies connected by multiple axes to multiple bodies of length 0
%connected by single axes

ax = cell(nbod, 1);         %rotational axes that connect bod(i) to bod(i-1)
                            %in bod(i) coordinates
joints = zeros(nbod,1);
for index = 1:nbod-1
    ax{index} = cat(1, nmcb.bod(index).rDOF.axis)';
    joints(index) = size(ax{index},2);
end
njoints = sum(joints);

endpoint = zeros(3,njoints+1); %origin of bod(i+1) in bod(i) coordinates
worldpoint = zeros(3, njoints+1);%origin of bod(i) in global coordinates
nextjoint = 1;
for index = 1:(nbod-1)%last body doesn't have a joint
    endpoint(:,nextjoint) = nmcb.bod(index).location;
    nextjoint = sum(joints(1:index))+1;
end
endpoint(:,njoints+1) = nmcb.en.pe.poi;    %assumes a perturbation exists and gives
                                    %the system endpoint
ax = cat(2, ax{:});                 %assumes unit axes

% get rotation matrices
cumrot = eye(3);
rots = zeros(3,3,njoints);
for index = 1:njoints
    rots(:,:,index) = axis2R(ax(:,index)*q(index));
    cumrot = squeeze(rots(:,:,index))*cumrot;
    worldpoint(:,index+1,1) = worldpoint(:,index,1) + ...
        cumrot*endpoint(:,index+1);
end

%% Find world point corresponding to flexion axes 

knee_points = worldpoint(:,7:8);
ankle_points = worldpoint(:,9:10);

knee_flex = interp1(knee_points(3,:)',knee_points(1:2,:)',zplane)';
ankle_flex = interp1(ankle_points(3,:)',ankle_points(1:2,:)',zplane,'linear','extrap')';

%% Convert world points back to segment coordinates

