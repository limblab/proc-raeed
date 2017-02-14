function toepoint = get_toepoint(legmodel,q)
% get position of toe in 2d world coordinates, given configuration q, in [hip angle;knee angle;ankle angle]

[worldpoint,~] = get_legpts(legmodel,q);

toepoint = worldpoint(:,end);