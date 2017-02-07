function R = axis2R(ax)
%R = axis2R(axis) converts the 3x1 axis of rotation, where the magnitude of
%rotation is encoded in the axis length, to a rotation matrix

if size(ax,2)==3
    ax = ax';
end

q = sqrt(sum(ax.^2));
if q==0
    R = eye(3);
else
    u = ax/q;
    ux = [0 -u(3) u(2);u(3) 0 -u(1);-u(2) u(1) 0];
    R = eye(3)*cos(q) + sin(q)*ux + (1-cos(q))*(u*u');
end