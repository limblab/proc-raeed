%% hindlimb iris plot
angs_elast = yupd(VAF_cart_unc>0.4 & VAF_cart_con>0.4);
angs_fixed = ycpd(VAF_cart_unc>0.4 & VAF_cart_con>0.4);

rand_ind = randperm(length(angs_elast),75);

%plot circles
figure
h=polar(linspace(-pi,pi,1000),ones(1,1000));
set(h,'linewidth',2,'color',[0 1 0])
hold all
h=polar(linspace(-pi,pi,1000),0.5*ones(1,1000));
set(h,'linewidth',2,'color',[0 0 0])

% plot changes with alpha dependent on CI width
for unit_ctr = 1:length(rand_ind)
    h=polar(linspace(angs_elast(rand_ind(unit_ctr)),angs_fixed(rand_ind(unit_ctr)),2),linspace(0.5,1,2));
    set(h,'linewidth',2,'color',[0.1 0.6 1])
end

%plot circles
h=polar(linspace(-pi,pi,1000),ones(1,1000));
set(h,'linewidth',2,'color',[0 1 0])
hold all
h=polar(linspace(-pi,pi,1000),0.5*ones(1,1000));
set(h,'linewidth',2,'color',[0 0 0])

set(findall(gcf, 'String','  0.2','-or','String','  0.4','-or','String','  0.6','-or','String','  0.8',...
        '-or','String','  1') ,'String', ' '); % remove a bunch of labels from the polar plot; radial and tangential
    
%% plot change in PD as a function of initial PD
angs_elast = yupd(VAF_cart_unc>0.4 & VAF_cart_con>0.4);
angs_fixed = ycpd(VAF_cart_unc>0.4 & VAF_cart_con>0.4);
angs_diff = angs_fixed-angs_elast;
angs_diff(angs_diff>pi) = angs_diff(angs_diff>pi)-2*pi;
angs_diff(angs_diff<-pi) = angs_diff(angs_diff<-pi)+2*pi;

dirs = linspace(-pi,pi,101)';
dirs(end) = [];
change_dirs = zeros(size(dirs));
CIhigh_change_dirs = change_dirs;
CIlow_change_dirs = change_dirs;
for i=1:length(dirs)
    relevant_angs = 180/pi*angs_diff(angs_elast>dirs(i) & angs_elast<dirs(i)+pi/50);
    change_dirs(i) = mean(abs(relevant_angs));
%     std_dir = std(abs(relevant_angs));
%     tscore = tinv(0.975,length(relevant_angs)-1); % t-score for 95% CI
    CIhigh_change_dirs(i) = prctile(relevant_angs,97.5);%change_dirs(i)+tscore*std_dir; %high CI
    CIlow_change_dirs(i) = prctile(relevant_angs,2.5);%change_dirs(i)-tscore*std_dir; %low CI
end

figure
h=polar(repmat(dirs,2,1),repmat(change_dirs,2,1));
set(h,'linewidth',2,'color',[0 0 0])
% th_fill = [flipud(dirs); dirs(end); dirs(end); dirs];
% r_fill = [flipud(CIhigh_change_dirs); CIhigh_change_dirs(end); CIlow_change_dirs(end); CIlow_change_dirs];
% [x_fill,y_fill] = pol2cart(th_fill,r_fill);
% patch(x_fill,y_fill,[0.1 0.6 1],'facealpha',0.3,'edgealpha',0);