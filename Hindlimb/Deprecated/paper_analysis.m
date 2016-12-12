%%%% paper analysis
%% Set up path
if(ispc)
    homeFolder = 'C:\Users\Raeed\';
else
    homeFolder = '/home/raeed/';
end
% addpath(genpath('C:\Users\Raeed\Projects\limblab\ClassyDataAnalysis'))
% addpath(genpath('/home/raeed/Projects/limblab/ClassyDataAnalysis'))
addpath(genpath([homeFolder filesep 'Projects' filesep 'limblab' filesep 'proc-raeed' filesep 'Hindlimb' filesep 'leg_lib' filesep]))
cd([homeFolder 'Dropbox' filesep 'Research' filesep 'cat hindlimb' filesep 'Data' filesep])
% addpath('/home/raeed/Projects/limblab/proc-raeed/MultiWorkspace/lib/')
% cd('/home/raeed/Projects/limblab/data-raeed/MultiWorkspace/SplitWS/Han/20160322/area2/')

clear homeFolder

%% load neurons
load('sim_10000neuron_20151011.mat','neurons')

%% run hindlimb simulation
tic
num_sec = 2;
joint_elast = [1;1;1];
[coef_elast,coef_fixed,best_act_elast,best_act_fixed,endpoint_positions,is_best_elast,is_best_fixed,VAF_elast,VAF_fixed] = run_hindlimb(neurons,num_sec,joint_elast);
toc

%% Set up for figure gen
base_leg = get_baseleg;
PD_elast = atan2(coef_elast(3,:),coef_elast(2,:));
PD_fixed = atan2(coef_fixed(3,:),coef_fixed(2,:));
moddepth_elast = sqrt(sum(coef_elast(2:3,:).^2));
moddepth_fixed = sqrt(sum(coef_fixed(2:3,:).^2));

%% Generate figure 3 - firing rate heat maps

for i = 1:100
    figure(1234)
    clf
    plot_heat_map(base_leg,best_act_elast(i,:),endpoint_positions',PD_elast(i))
    figure(1235)
    clf
    plot_heat_map_con(base_leg,activity_con(i,:),endpoint_positions',PD_fixed(i))
    title(['Cart R2: ' num2str(VAF_elast(i(i)))])
    disp(['Unit number: ' num2str(i) ', Elastic PD: ' num2str(PD_elast(i)*180/pi) ', Knee-fixed PD: ' num2str(PD_fixed(i)*180/pi) ', PD diff: ' num2str((PD_fixed(i)-PD_elast(i))*180/pi)])
    
    waitforbuttonpress
end

%% Generate figure 4A - PD distribution
plot_PD_distr(randsample(PD_elast,800,true),36)
hold on

center_ep = mean(endpoint_positions(:,[45 46 55 56]),2);
[~,~,~,segment_angles_unc] = find_kinematics(base_leg,center_ep, 0, joint_elast);
legpts = get_legpts(base_leg,segment_angles_unc);
ep = legpts(:,base_leg.segment_idx(end,end));
hip_rot = legpts(:,base_leg.segment_idx(1,1));

for i = 1:3
    s=base_leg.segment_idx(i,:);
    plot((legpts(1,s)-ep(1))/20, (legpts(2,s)-ep(2))/20, 'k-','LineWidth',2)
    plot((legpts(1,s)-ep(1))/20, (legpts(2,s)-ep(2))/20, 'bo', 'MarkerSize',10, 'LineWidth',2)
end

hold off

%% Generate figure 5A - cosdPD histogram
cosdPD = cos(PD_fixed-PD_elast);
figure; hist(cosdPD,40)
set(gca,'xlim',[0 1])

%% Generate figure 6 - muscle tunings (own script called check_muscle_dir)
check_muscle_dir;

%% Generate reported numbers

% percent tuned neurons in each case
disp(['Percent tuned in elastic condition: ' num2str(sum(is_best_elast)/length(neurons)*100)])
disp(['Percent tuned in knee-fixed condition: ' num2str(sum(is_best_fixed)/length(neurons)*100)])
disp(['Percent tuned in both conditions: ' num2str(sum(is_best_elast & is_best_fixed)/length(neurons)*100)])

% median PD change
disp(['Median cosine \Delta PD: ' num2str(median(cosdPD))])
disp(['Median absolute \Delta PD: ' num2str(acosd(median(cosdPD)))])

% principal axis direction (neurons)
% first double the angles because the distribution looks bimodal
PD_distr_double = remove_wrap(2*PD_elast);
PD_mean = circ_mean(PD_distr_double)/2;
% Rayleigh test
[pval_rtest,z_rtest] = circ_rtest(PD_distr_double);
disp(['Principal axis of neural PDs: ' num2str(PD_mean*180/pi) ' with p = ' num2str(pval_rtest)])


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

%% Get biarticular-free values
biart_free_neurons =  neurons;
biart_free_neurons(:,[3 4 6]) = zeros(length(biart_free_neurons),3);
[biart_coef_elast,biart_coef_fixed] = run_hindlimb(biart_free_neurons,num_sec,joint_elast);

biart_PD_elast = atan2(biart_coef_elast(3,:),biart_coef_elast(2,:));
biart_PD_fixed = atan2(biart_coef_fixed(3,:),biart_coef_fixed(2,:));
biart_cosdPD = cos(biart_PD_fixed-biart_PD_elast);

disp(['Percent tuned without biarticulars: ' num2str(length(biart_PD_elast)/length(biart_free_neurons))])
disp(['Median cosine \Delta PD w/o biarticulars: ' num2str(median(biart_cosdPD))])
disp(['Median absolute \Delta PD w/o biarticulars: ' num2str(acosd(median(biart_cosdPD)))])

%% Get joint-based sim values
rng('default')
joint_neurons = random('Normal', 0, 1, 10000, 3);
[joint_coef_elast,joint_coef_fixed] = run_hindlimb_joint(joint_neurons,num_sec,joint_elast);

joint_PD_elast = atan2(joint_coef_elast(3,:),joint_coef_elast(2,:));
joint_PD_fixed = atan2(joint_coef_fixed(3,:),joint_coef_fixed(2,:));
joint_cosdPD = cos(joint_PD_fixed-joint_PD_elast);

disp(['Percent tuned without biarticulars: ' num2str(length(joint_PD_elast)/length(biart_free_neurons))])
disp(['Median cosine \Delta PD w/o biarticulars: ' num2str(median(joint_cosdPD))])
disp(['Median absolute \Delta PD w/o biarticulars: ' num2str(acosd(median(joint_cosdPD)))])