function varargout = drawmodel(nmo,q)
%drawModel(nmc_struct, q) animates a stick figure described by the
%Neuromechanic model NMC_STRUCT to the joint angles given in Q. tDOFS are
%ignored.

%if passed nmco, extract the nmcb
if isfield(nmo, 'nmcb'), nmo = nmo.nmcb; end

nbod = length(nmo.bod);
if length(q)~=numel(q)
    npos = size(q, 2);
else
    npos = 1;
end

%NMCB structure allows multiple axes connecting 2 bodies, which really
%complicates calculations.  We're going to convert that to a series of
%segments connected by single rotational degrees of freedom by replacing
%single bodies connected by multiple axes to multiple bodies of length 0
%connected by single axes

ax = cell(nbod, 1);         %rotational axes that connect bod(i) to bod(i-1)
                            %in bod(i) coordinates
joints = zeros(nbod,1);
for index = 1:nbod-1
    ax{index} = cat(1, nmo.bod(index).rDOF.axis)';
    joints(index) = size(ax{index},2);
end
njoints = sum(joints);

endpoint = zeros(3,njoints+1); %origin of bod(i+1) in bod(i) coordinates
worldpoint = zeros(3, njoints+1, npos);%origin of bod(i) in global coordinates
nextjoint = 1;
for index = 1:(nbod-1)%last body doesn't have a joint
    endpoint(:,nextjoint) = nmo.bod(index).location;
    nextjoint = sum(joints(1:index))+1;
end
endpoint(:,njoints+1) = nmo.en.pe.poi;    %assumes a perturbation exists and gives
                                    %the system endpoint
ax = cat(2, ax{:});                 %assumes unit axes

%Draw the starting configuration
cumrot = eye(3);
for index = 1:njoints
    cumrot = axis2R(ax(:,index)*q(index))*cumrot;
    worldpoint(:,index+1,1) = worldpoint(:,index,1) + ...
        cumrot*endpoint(:,index+1);
end
h=plot3(worldpoint(1,:,1), worldpoint(2,:,1), worldpoint(3,:,1), 'k.-');
axis equal

%Loop through any additional states, updating configuration as we go
for i1 = 2:npos
    cumrot = eye(3);
    for index = 1:njoints
    cumrot = axis2R(ax(:,index)*q(index,i1))*cumrot;
    worldpoint(:,index+1,i1) = worldpoint(:,index,i1) + cumrot*endpoint(:,index+1);
    end
    set(h, ...
        'xdata', worldpoint(1,:,i1), ...
        'ydata', worldpoint(2,:,i1), ...
        'zdata', worldpoint(3,:,i1));
    drawnow
   pause(0.2)
end

if nargout>0, varargout{1} = h; end
if nargout>1, varargout{2} = worldpoint; end


function R = axis2R(ax)
%R = axis2R(axis) converts the 3x1 axis of rotation, where the magnitude of
%rotation is encoded in the axis length, to a rotation matrix

q = sqrt(sum(ax.^2));
if q==0
    R = eye(3);
else
    u = ax/q;
    ux = [0 -u(3) u(2);u(3) 0 -u(1);-u(2) u(1) 0];
    R = eye(3)*cos(q) + sin(q)*ux + (1-cos(q))*(u*u');
end