function draw_hindlimb(legmodel,q,show_muscles)
% Draws 2D hindlimb given by configuration q, with segments in black and
% joints in blue circles. If show_muscles == true, muscles will be drawn
% in red.

%% get leg points
[worldpoint,oiv_world] = get_legpts(legmodel,q);

%% plot muscle points to check
holdstat = ishold;
plot(worldpoint(1,:), worldpoint(2,:), 'k-','linewidth',2);
hold on
plot(worldpoint(1,:), worldpoint(2,:), 'bo','markersize',10,'linewidth',2);
if(show_muscles)
    for musc_idx = 1:length(oiv_world)
        indiv_oiv_world = oiv_world{musc_idx};
        plot(indiv_oiv_world(:,1),indiv_oiv_world(:,2),'r.-','linewidth',2)
    end
    axis equal
end
if(~holdstat)
    hold off
end