function [muscle_coef_elast,muscle_coef_fixed] = check_muscle_dir
%%% Checking muscle "global pulling directions"
%% initialize leg
clear
base_leg=get_baseleg;

%% %%%%
% Get endpoint positions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
num_positions = 100;

mp = get_legpts(base_leg,[pi/4 -pi/4 pi/4]);
mtp = mp(:,base_leg.segment_idx(end,end));

[a,r]=cart2pol(mtp(1), mtp(2));

% get polar points
rs = linspace(-4,1,10) + r;
% as = pi/16 * linspace(-2,4,10) + a;
as = pi/180 * linspace(-30,25,10) + a;

[rsg, asg] = meshgrid(rs, as);
polpoints = [reshape(rsg,[1,num_positions]); reshape(asg,[1,num_positions])];

[x, y] = pol2cart(polpoints(2,:), polpoints(1,:));
endpoint_positions = [x;y];

%% %%%%%%%%%%%
% Find kinematics of limb in endpoint positions
%%%%%%%%%%%
joint_elast = [1;1;1];
[~,~,scaled_lengths] = find_kinematics(base_leg,endpoint_positions,false,joint_elast);
scaled_lengths_unc = scaled_lengths{1};
scaled_lengths_con = scaled_lengths{2};

%% %%%%%%%%%%%
% Find linear approximation to muscle lengths
%%%%%%%%%%%%%%

zerod_ep = endpoint_positions' - repmat(mean(endpoint_positions'),length(endpoint_positions'),1);

pred_length_unc = zeros(size(scaled_lengths_unc));
pred_length_con = zeros(size(scaled_lengths_con));

for i = 1:size(scaled_lengths_unc,2)
    length_fit_unc = LinearModel.fit(zerod_ep,scaled_lengths_unc(:,i));
    length_fit_con = LinearModel.fit(zerod_ep,scaled_lengths_con(:,i));
    
    pred_length_unc(:,i) = predict(length_fit_unc,zerod_ep);
    pred_length_con(:,i) = predict(length_fit_con,zerod_ep);
end

%% %%%%%%%%%%%%%%%%%%%%
% Calculate pulling directions
%%%%%%%%%%%%%%%%%%%%%%%%%

% only check muscles
neurons = eye(8);
activity_con = neurons*scaled_lengths_con';
activity_unc = neurons*scaled_lengths_unc';

yc = [];
yu = [];

cart_fit_con = cell(length(neurons),1);
cart_fit_unc = cell(length(neurons),1);

for i=1:length(neurons)
    ac = activity_con(i,:)';
    au = activity_unc(i,:)';
        
    cart_fit_con{i} = LinearModel.fit(zerod_ep,ac);
    cart_fit_unc{i} = LinearModel.fit(zerod_ep,au);
    
    yc = [yc cart_fit_con{i}.Coefficients.Estimate];
    yu = [yu cart_fit_unc{i}.Coefficients.Estimate];
end

%% Set outputs
muscle_coef_elast = yu(2:3,:);
muscle_coef_fixed = yc(2:3,:);

%% Get prefered directions
ycpd = atan2(yc(3,:),yc(2,:));
yupd = atan2(yu(3,:),yu(2,:));

%% plot preferred directions
handles = zeros(1,8);

moddepth_unc = sqrt(yu(2,:).^2+yu(3,:).^2);
moddepth_con = sqrt(yc(2,:).^2+yc(3,:).^2);

baseline_unc = yu(1,:);
baseline_con = yc(1,:);

% get principal components
[pca_coeff_unc,~,eig_unc] = pca(yu(2:3,:)');
[pca_coeff_con,~,eig_con] = pca(yc(2:3,:)');

theta=linspace(-pi,pi,100)';
ellipse_unc = [sqrt(eig_unc(1))*cos(theta) sqrt(eig_unc(2))*sin(theta)]*pca_coeff_unc;
ellipse_con = [sqrt(eig_con(1))*cos(theta) sqrt(eig_con(2))*sin(theta)]*pca_coeff_con;

figure_handles(1) = figure;
% subplot(1,2,1)
h1 = polar(0,.2,'.');
set(h1,'MarkerSize',0.1)
colors = linspecer(8);
hold on
for i = 1:length(neurons)
    handles(i) = polar([yupd(i) yupd(i)],[0 moddepth_unc(i)]);
    h2 = polar(yupd(i),moddepth_unc(i),'o');
    
%     handles(i) = polar([yupd(i) yupd(i)],[baseline_unc(i)-moddepth_unc(i) baseline_unc(i)+moddepth_unc(i)]);

    set(handles(i),'Color',colors(i,:),'LineWidth',3)
    set(h2,'Color',colors(i,:),'LineWidth',3)
    
%     h3 = polar(yupd(i),baseline_unc(i),'o');
%     set(h3,'Color',colors(8*i,:),'LineWidth',3)
    
    hold on
%     pause(.01)
end
[theta,rho] = cart2pol(ellipse_unc(:,1),ellipse_unc(:,2));
h=polar(theta,rho);
set(h,'linewidth',2)

% muscle order: BFA IP RF1 RF2 BFP VL MG SOL TA
legend(handles,'BFA','IP','RF','BFP','VL','MG','SOL','TA')
title 'Global pulling directions of muscles (Unc)'

% subplot(1,2,2)
figure_handles(2) = figure;
h1 = polar(0,.2,'.');
set(h1,'MarkerSize',0.1)
hold on
for i = 1:length(neurons)
    handles(i) = polar([ycpd(i) ycpd(i)],[0 moddepth_con(i)]);
    h2 = polar(ycpd(i),moddepth_con(i),'o');
    
%     handles(i) = polar([yupd(i) yupd(i)],[baseline_unc(i)-moddepth_unc(i) baseline_unc(i)+moddepth_unc(i)]);

    set(handles(i),'Color',colors(i,:),'LineWidth',3)
    set(h2,'Color',colors(i,:),'LineWidth',3)
    
%     h3 = polar(yupd(i),baseline_unc(i),'o');
%     set(h3,'Color',colors(8*i,:),'LineWidth',3)
    
    hold on
%     pause(.01)
end
[theta,rho] = cart2pol(ellipse_con(:,1),ellipse_con(:,2));
h=polar(theta,rho);
set(h,'linewidth',2)

% muscle order: BFA IP RF1 RF2 BFP VL MG SOL TA
% legend(handles,'BFA','IP','RF','BFP','VL','MG','SOL','TA')
title 'Global pulling directions of muscles (Con)'

%% plot directional changes
figure_handles(3) = figure;
% subplot(1,2,1)
h1 = polar(0,.2,'.');
set(h1,'MarkerSize',0.1)
hold on
for i = 1:length(neurons)
    handles(i) = polar([yupd(i) ycpd(i)],[moddepth_unc(i) moddepth_con(i)]);
    
    set(handles(i),'Color',colors(i,:),'LineWidth',3)
    
    hold on
end

%% find expected axis of neural GD distribution
% clear i
% mean_axis = angle(sum(moddepth_unc.*exp(1i*yupd*2)))/2;
% mean_vect = [cos(mean_axis);sin(mean_axis)];
% perp_vect = [-sin(mean_axis);cos(mean_axis)];
% 
% %% find changes in vectors along main axis and normal to main axis
% axis_tuning_unc = [mean_vect perp_vect]'*yu(2:3,:);
% axis_tuning_con = [mean_vect perp_vect]'*yc(2:3,:);
% 
% axis_changes = axis_tuning_con-axis_tuning_unc;
% 
% relative_axis_changes = axis_changes./repmat(moddepth_unc,2,1);

%% find changes along principal axis and orthogonal axis
muscle_tuning_unc = yu(2:3,:)';
muscle_tuning_con = yc(2:3,:)';

proj_unc = muscle_tuning_unc*pca_coeff_unc;
proj_con = muscle_tuning_con*pca_coeff_con;
totalchange = sum(proj_con-proj_unc);
abschange = sum(abs(proj_con-proj_unc));

disp(['Total projected muscle changes: ' num2str(totalchange(1)) ', ' num2str(totalchange(2))])
disp(['Absolute projected muscle changes: ' num2str(abschange(1)) ', ' num2str(abschange(2))])

disp(['Principal axis elast: ' num2str(atan2d(pca_coeff_unc(2,1),pca_coeff_unc(1,1)))])
disp(['Principal axis fixed: ' num2str(atan2d(pca_coeff_con(2,1),pca_coeff_con(1,1)))])

disp(['Variance accounted for by principal axis (elast): ' num2str(eig_unc(1)/sum(eig_unc))])
disp(['Variance accounted for by principal axis (fixed): ' num2str(eig_con(1)/sum(eig_con))])
%% plot ellipses



% figure
% subplot(121)
% plot_PD_distr(yupd,100);
% title 'Unconstrained PD Distribution'
% % figure
% subplot(122)
% plot_PD_distr(ycpd,100);
% title 'Constrained PD Distribution'

%% plot heatmaps
% for i = 1:length(neurons)
%     ac = activity_con(i,:)';
%     au = activity_unc(i,:)';
%     
%     figure
%     plot_heat_map(au,zerod_ep)
% end