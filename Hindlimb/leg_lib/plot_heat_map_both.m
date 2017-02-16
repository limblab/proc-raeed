function plot_heat_map_both(legmodel,act_unc,act_con,ep,PD_unc,PD_con,joint_elast)
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
    
    center_ep = mean(ep([45 46 55 56],:))';
%     corner_ep = ep([10 91],:)';
    corner_ep = ep([1 100],:)';
%     corner_ep = ep';
    [joint_angles_center,~,~] = find_kinematics(legmodel,center_ep, 0,joint_elast);
    [joint_angles_corner,~,~] = find_kinematics(legmodel,corner_ep, 0,joint_elast);
    joint_angles_center_unc = joint_angles_center{1};
    joint_angles_center_con = joint_angles_center{2};
    joint_angles_corner_unc = joint_angles_corner{1};
    joint_angles_corner_con = joint_angles_corner{2};
    
    map = colormap(jet);
    colorvec_unc = interp1(linspace(0,1,length(map))',map,act_scaled_unc(:));
    
    subplot(121)
    scatter(ep(:,1),ep(:,2),100,colorvec_unc,'filled')
    hold on
    draw_hindlimb(legmodel,joint_angles_center_unc',false)
    for i=1:size(joint_angles_corner_unc,1)
        draw_hindlimb(legmodel,joint_angles_corner_unc(i,:)',false)
    end
    PD_end = 7/100*[cos(PD_unc);sin(PD_unc)]+center_ep;
    plot([center_ep(1) PD_end(1)],[center_ep(2) PD_end(2)],'-r','linewidth',4)
    colorbar('YTick',[0 1],'YTickLabel',{[num2str(min_act) ' Hz'], [num2str(max_act) ' Hz']})
    set(gca,'box','off','tickdir','out','xtick',center_ep(1),'ytick',center_ep(2),'xticklabel',{},'yticklabel',{});
%     axis off
    axis equal
    
    subplot(122)
    colorvec_con = interp1(linspace(0,1,length(map))',map,act_scaled_con(:));
    scatter(ep(:,1),ep(:,2),100,colorvec_con,'filled')
    hold on
    draw_hindlimb(legmodel,joint_angles_center_con',false)
    for i=1:size(joint_angles_corner_con,1)
        draw_hindlimb(legmodel,joint_angles_corner_con(i,:)',false)
    end
    PD_end = 7/100*[cos(PD_con);sin(PD_con)]+center_ep;
    plot([center_ep(1) PD_end(1)],[center_ep(2) PD_end(2)],'-r','linewidth',4)
    colorbar('YTick',[0 1],'YTickLabel',{[num2str(min_act) ' Hz'], [num2str(max_act) ' Hz']})
    set(gca,'box','off','tickdir','out','xtick',center_ep(1),'ytick',center_ep(2),'xticklabel',{},'yticklabel',{});
%     axis off
    axis equal
end