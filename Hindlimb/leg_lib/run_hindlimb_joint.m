function [out_table_unc,out_table_con,endpoint_positions] = run_hindlimb_joint(neurons,num_sec,joint_elast)
% Runs hindlimb simulation given neural weights, recording time, and joint
% elasticity

%% set up
base_leg = get_baseleg;
plotflag = false;

%% Get workspace
num_positions = 100;

mp = get_legpts(base_leg,[pi/4 -pi/4 pi/4]);
mtp = mp(:,base_leg.segment_idx(end,end));

[a,r]=cart2pol(mtp(1), mtp(2));

% get polar points
rs = linspace(-4,1,10) + r;
% rs = linspace(-4,1.5,10) + r;
%rs = r;
% as = pi/16 * linspace(-2,4,10) + a;
% as = pi/180 * linspace(-33,33,10) + a;
as = pi/180 * linspace(-30,25,10) + a;
%as = a;

[rsg, asg] = meshgrid(rs, as);
polpoints = [reshape(rsg,[1,num_positions]); reshape(asg,[1,num_positions])];

[x, y] = pol2cart(polpoints(2,:), polpoints(1,:));
endpoint_positions = [x;y];

%% Find joint angles for paw positions
[joint_angles,~,~] = find_kinematics(base_leg,endpoint_positions,plotflag,joint_elast);
joint_angles_unc = joint_angles{1};
joint_angles_con = joint_angles{2};

max_joint_angles = max([joint_angles_unc;joint_angles_con]);
min_joint_angles = min([joint_angles_unc;joint_angles_con]);
range_joint_angles = max_joint_angles-min_joint_angles;

min_rep = repmat(min_joint_angles,num_positions,1);
range_rep = repmat(range_joint_angles,num_positions,1);

scaled_joint_angles_unc = (joint_angles_unc-min_rep)./range_rep;
scaled_joint_angles_con = (joint_angles_con-min_rep)./range_rep;

clear min_rep
clear range_rep

%% Get neural activity based on num_sec
activity_unc = get_activity(neurons,scaled_joint_angles_unc,num_sec);
activity_con = get_activity(neurons,scaled_joint_angles_con,num_sec);

%% get fits

coef_con = zeros(3,length(neurons));
coef_unc = zeros(3,length(neurons));

VAF_cart_con = zeros(1,length(neurons));
VAF_cart_unc = zeros(1,length(neurons));

pval_con = zeros(1,length(neurons));
pval_unc = zeros(1,length(neurons));

zerod_ep = endpoint_positions' - repmat(mean(endpoint_positions'),length(endpoint_positions'),1);

cart_fit_con = cell(length(neurons),1);
cart_fit_unc = cell(length(neurons),1);

for i=1:length(neurons)
    ac = activity_con(i,:)';
    au = activity_unc(i,:)';
    
    cart_fit_con{i} = LinearModel.fit(zerod_ep,ac);
    cart_fit_unc{i} = LinearModel.fit(zerod_ep,au);
    
    temp_c = cart_fit_con{i}.Coefficients.Estimate;
    temp_u = cart_fit_unc{i}.Coefficients.Estimate;
    coef_con(:,i) = temp_c;
    coef_unc(:,i) = temp_u;
    
    VAF_cart_con(i) = cart_fit_con{i}.Rsquared.Ordinary;
    VAF_cart_unc(i) = cart_fit_unc{i}.Rsquared.Ordinary;
    
    pval_con(i) = coefTest(cart_fit_con{i});
    pval_unc(i) = coefTest(cart_fit_unc{i});
end

%% assign tuning table output
out_table_unc = table(neurons,activity_unc,coef_unc',VAF_cart_unc',pval_unc',(VAF_cart_unc>0.4 & pval_unc<0.01)',...
    'VariableNames',{'weights','activity','coef','VAF','pval','isTuned'});
out_table_con = table(neurons,activity_con,coef_con',VAF_cart_con',pval_con',(VAF_cart_con>0.4 & pval_con<0.01)',...
    'VariableNames',{'weights','activity','coef','VAF','pval','isTuned'});

%% Get only tuned neurons
% is_best_unc = VAF_cart_unc>0.4 & pval_unc<0.01;
% is_best_con = VAF_cart_con>0.4 & pval_con<0.01;
% is_best = is_best_unc & is_best_con;
% 
% best_coef_con = coef_con(:,is_best);
% best_coef_unc = coef_unc(:,is_best);
% 
% best_act_con = activity_con(is_best,:);
% best_act_unc = activity_unc(is_best,:);

%% Get prefered directions

% PD_con = atan2(best_coef_con(3,:),best_coef_con(2,:));
% PD_unc = atan2(best_coef_unc(3,:),best_coef_unc(2,:));

