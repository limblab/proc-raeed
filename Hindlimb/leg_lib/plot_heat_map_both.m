function plot_heat_map_both(base_leg,act_unc,act_con,zerod_ep,PD_unc,PD_con,joint_elast)
%% plot heat map of neurons in cartesian space
    
    % scale this activity to between 0 and 1
%     stdev_act = std(act);
%     mean_act = mean(act);
%     min_act = mean_act-2*stdev_act;
%     max_act = mean_act+2*stdev_act;
    min_act = min([act_unc act_con]);
    max_act = max([act_unc act_con]);
    
    act_scaled_unc = (act_unc-min_act)/(max_act-min_act);
    act_scaled_con = (act_con-min_act)/(max_act-min_act);
    
    center_ep = mean(zerod_ep([45 46 55 56],:))';
    corner_ep = zerod_ep([10 91],:)';
    [~,~,~,segment_angles_center_unc,segment_angles_center_con] = find_kinematics(base_leg,center_ep, 0,joint_elast);
    [~,~,~,segment_angles_corner_unc,segment_angles_corner_con] = find_kinematics(base_leg,corner_ep, 0,joint_elast);
    
    map = colormap(jet);
    colorvec_unc = interp1(linspace(0,1,length(map))',map,act_scaled_unc(:));
    
    subplot(121)
    scatter(zerod_ep(:,1),zerod_ep(:,2),100,colorvec_unc,'filled')
    hold on
    draw_bones(base_leg,segment_angles_center_unc,true,3)
    for i=1:2
        draw_bones(base_leg,segment_angles_corner_unc(i,:),true,3)
    end
    PD_end = 7*[cos(PD_unc);sin(PD_unc)]+center_ep;
    plot([center_ep(1) PD_end(1)],[center_ep(2) PD_end(2)],'-k','linewidth',4)
    colorbar('YTick',[0 1],'YTickLabel',{[num2str(min_act) ' Hz'], [num2str(max_act) ' Hz']})
    axis off
    axis equal
    
    subplot(122)
    colorvec_con = interp1(linspace(0,1,length(map))',map,act_scaled_con(:));
    scatter(zerod_ep(:,1),zerod_ep(:,2),100,colorvec_con,'filled')
    hold on
    draw_bones(base_leg,segment_angles_center_con,true,3)
    for i=1:2
        draw_bones(base_leg,segment_angles_corner_con(i,:),true,3)
    end
    PD_end = 7*[cos(PD_con);sin(PD_con)]+center_ep;
    plot([center_ep(1) PD_end(1)],[center_ep(2) PD_end(2)],'-k','linewidth',4)
    colorbar('YTick',[0 1],'YTickLabel',{[num2str(min_act) ' Hz'], [num2str(max_act) ' Hz']})
    axis off
    axis equal
end