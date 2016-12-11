function [C,Ceq] = endpoint_constraint(angles,endpoint,base_leg)
% constraint to match endpoint
joint_transform = [1 0 0; 1 -1 0; 0 -1 1]';

legpts = get_legpts(base_leg,angles'/joint_transform);
current_ep = legpts(:,base_leg.segment_idx(end,end));

C = [];
Ceq = sum((current_ep-endpoint).^2);