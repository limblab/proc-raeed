function [num_tuned,cosPDChange,pdChange,PD_unc,PD_con] = run_hindlimb(neurons,num_sec,joint_elast)

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
[joint_angles,muscle_lengths,scaled_lengths] = find_kinematics(base_leg,endpoint_positions,plotflag,joint_elast);
joint_angles_unc = joint_angles{1};
joint_angles_con = joint_angles{2};
muscle_lengths_unc = muscle_lengths{1};
muscle_lengths_con = muscle_lengths{2};
scaled_lengths_unc = scaled_lengths{1};
scaled_lengths_con = scaled_lengths{2};

%% Get neural activity based on num_sec
activity_unc = get_activity(neurons,scaled_lengths_unc,num_sec);
activity_con = get_activity(neurons,scaled_lengths_con,num_sec);

%% get fits

coef_con = [];
coef_unc = [];

VAF_cart_con = [];
VAF_cart_unc = [];

zerod_ep = endpoint_positions' - repmat(mean(endpoint_positions'),length(endpoint_positions'),1);

cart_fit_con = cell(length(neurons),1);
cart_fit_unc = cell(length(neurons),1);
joint_fit_con = cell(length(neurons),1);
joint_fit_unc = cell(length(neurons),1);


for i=1:length(neurons)
    ac = activity_con(i,:)';
    au = activity_unc(i,:)';
    
    cart_fit_con{i} = LinearModel.fit(zerod_ep,ac);
    cart_fit_unc{i} = LinearModel.fit(zerod_ep,au);
    
    temp_c = cart_fit_con{i}.Coefficients.Estimate;
    temp_u = cart_fit_unc{i}.Coefficients.Estimate;
    coef_con = [coef_con temp_c];
    coef_unc = [coef_unc temp_u];
    
    VAF_cart_con = [VAF_cart_con cart_fit_con{i}.Rsquared.Ordinary];
    VAF_cart_unc = [VAF_cart_unc cart_fit_unc{i}.Rsquared.Ordinary];
    
    % do joint regressions
%     joint_fit_con{i} = LinearModel.stepwise(joint_angles_con,ac,'linear', 'upper', 'linear', 'PRemove', 0.1, 'PEnter', 0.01);
%     joint_fit_unc{i} = LinearModel.stepwise(joint_angles_unc,au,'linear', 'upper', 'linear', 'PRemove', 0.1, 'PEnter', 0.01);
    
    % check if they're the same
%     joint_comp = strcmp(joint_fit_con{i}.PredictorNames,joint_fit_unc{i}.PredictorNames);
%     joint_same(i) = (sum(joint_comp)/length(joint_comp) == 1);
end

%% Get only tuned neurons
is_best = VAF_cart_unc>0.4 & VAF_cart_con>0.4;
num_tuned = sum(is_best);

best_coef_con = coef_con(:,is_best);
best_coef_unc = coef_unc(:,is_best);

%% Get prefered directions

PD_con = atan2(best_coef_con(3,:),best_coef_con(2,:));
PD_unc = atan2(best_coef_unc(3,:),best_coef_unc(2,:));

cosdPD = cos(PD_con-PD_unc);

%% output variables
cosPDChange = median(cosdPD);
pdChange = acosd(median(cosdPD));

