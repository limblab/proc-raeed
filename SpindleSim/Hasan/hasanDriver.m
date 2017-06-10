% hasanDriver.m
%
% Created 2013/06 by Kyle P. Blum
% Modified 2017/05 by Kyle P. Blum
% 1) Added in descriptions of parameters and organized code into sections
%
% This script initializes simulations for the Hasan 1983 muscle spindle
% model. There are 4 models outlined in the Hasan 1983 paper: 1) Primary
% ending with dynamic gamma, 2) Primary ending with static gamma, 3)
% Secondary deeferented ending, and 4) Primary deeferented ending. 


clear,clc,close all
modelflag = 4;


models = {'Triangle Response Model','Primary Dynamic Gamma'...
    'Primary Static Gamma','Secondary Deefferented',...
    'Primary Deefferented'};
perts = {'Ramp & Hold Pert'};





%% PERTURBATION SETUP %%


% Ramp, hold, and return
        dt = 0.001;
        x0 = 10;                       % Initial Length of sensory + nonsensory ending
        stretch_amp = 5;               % mm
        max_len = x0 + stretch_amp;    % 
        max_vel = 20;                   % mm/s
        max_acc = 1000;              % mm/s^2
        rampdown = 1;
        [t_x,~,dxdt,x] = rampandhold(max_len,max_vel,max_acc,x0,dt,rampdown);


%% MODEL PARAMETER SETUP %%



    switch modelflag
        
        case 1 % Primary ending w/ Dynamic Gamma
            a = 0.1;   % mm/s
            b = 125;   % unitless
            c = -15;   % change from maximum in situ length, mm
            h = 250;   % Linear gain, spikes/(s*mm)
            p = 0.1;   % Derivative gain, s
            g = 1;     % Length gain (not in original model)
            offset = 0;% Not included in Hasan model, but mentioned in 1983 paper
        case 2 % Primary ending w/ Static Gamma
            a = 100;
            b = 100;
            c = -25;
            h = 200;
            p = 0.01;
            g = 1;
            offset = 0;
        case 3 % Secondary Deeferented
            a = 50;
            b = 250;
            c = -20;
            h = 80;
            p = 0.1;
            g = 1;
            offset = 0;
        case 4 % Primary Deeferented
            a = 0.3;
            b = 250;
            c = -15;
            h = 350;
            p = 0.1;
            g = 1;
            offset = 0;
    end




%% RUN HASAN MODEL %%

[t,mu,dmudt,r] = hasan(a,b,c,h,p,g,offset,t_x,dxdt,x);



%% PLOTTING  %%

t_min = t(1);
t_max = t(end);

figure()
hold on
scnsize = get(0,'screensize');
set(gcf,'Color',[1 1 1],...
    'OuterPosition',scnsize/2,...
    'PaperOrientation','landscape',...
    'PaperPosition',[0.5,0.5,10,7]);
fsize = 18;

x_amp = max(x) - min(x);
x_min = min(x) - 0.1*x_amp;
x_max = max(x) + 0.1*x_amp;

subplot(4,1,1)
axis([t_min t_max x_min x_max])
hold on
plot(t_x,x,'linewidth',2)
ylabel('x(t) (mm)')
set(gca,'xticklabel',[],'fontsize',10)
title_text = ['Hasan Model: ' models{modelflag}];
title(title_text)

mu_amp = max(mu) - min(mu);
mu_min = min(mu) - 0.1*mu_amp;
mu_max = max(mu) + 0.1*mu_amp;

subplot(4,1,2)
axis([t_min t_max mu_min mu_max])
hold on
plot(t,mu)
ylabel(['\mu' '(t) (mm)'])
set(gca,'xticklabel',[],'fontsize',10)
                

dmu_amp = max(dmudt) - min(dmudt);
dmu_min = min(dmudt) - 0.1*dmu_amp;
dmu_max = max(dmudt) + 0.1*dmu_amp;

subplot(4,1,3)
axis([t_min t_max dmu_min dmu_max])
hold on
plot(t,dmudt)
ylabel(['d' '\mu' '/dt (mm/s)'])
set(gca,'xticklabel',[],'fontsize',10)

r_amp = max(r) - min(r);
r_min = min(r) - 0.1*r_amp;
r_max = max(r) + 0.1*r_amp;

subplot(4,1,4)
axis([t_min t_max min(r) max(r)])
hold on
plot(t,r)
ylabel('Firing Rate (pps)'),xlabel('time (s)')
set(gca,'fontsize',10)

