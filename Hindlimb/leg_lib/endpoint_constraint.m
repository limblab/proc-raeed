function [C,Ceq] = endpoint_constraint(angles,endpoint,legmodel)
% constraint to match endpoint

toepoint = get_toepoint(legmodel,angles);

C = [];
Ceq = sum((toepoint-endpoint).^2);