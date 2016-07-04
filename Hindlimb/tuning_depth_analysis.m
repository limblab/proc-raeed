%% Check length of tuning vectors
tuned = VAF_cart_unc>0.4 & VAF_cart_con>0.4;
depth_elast = sqrt(sum(yu(2:3,tuned).^2));
depth_fixed = sqrt(sum(yc(2:3,tuned).^2));

relative_depth_change = (depth_fixed-depth_elast)./depth_elast*100;

figure
hist(relative_depth_change,40)

figure
plot(depth_elast,depth_fixed-depth_elast,'o')

%%
angs_elast = yupd(VAF_cart_unc>0.4 & VAF_cart_con>0.4);
angs_fixed = ycpd(VAF_cart_unc>0.4 & VAF_cart_con>0.4);
angs_diff = angs_fixed-angs_elast;
angs_diff(angs_diff>pi) = angs_diff(angs_diff>pi)-2*pi;
angs_diff(angs_diff<-pi) = angs_diff(angs_diff<-pi)+2*pi;

dirs = linspace(-pi,pi,101)';
dirs(end) = [];
binned_depth_change = zeros(size(dirs));
for i=1:length(dirs)
    all_depth_change = relative_depth_change(angs_elast>dirs(i) & angs_elast<dirs(i)+pi/50);
    binned_depth_change(i) = mean(abs(all_depth_change));
end

figure
h=polar(repmat(dirs,2,1),repmat(binned_depth_change,2,1));
set(h,'linewidth',2,'color',[0 0 0])

%%
diff_vect = yc(2:3,tuned)-yu(2:3,tuned);
diff_dir = atan2(diff_vect(2,:),diff_vect(1,:));

plot_PD_distr(diff_dir,100)