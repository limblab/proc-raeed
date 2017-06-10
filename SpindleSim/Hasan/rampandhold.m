function [t,acc,vel,len] = rampandhold(max_len,max_vel,max_acc,init_len,dt,rampdown)
% Created 2017/05 by Kyle P. Blum
%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
       %%% SET UP PARAMETERS %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

init_rest_dur = 2;                                       % Duration of initial rest
accel_dur = max_vel/max_acc - dt;                          % Duration of acceleration
decel_dur = accel_dur;                                % Duration of deceleration
ramp_dur = ((max_len-init_len) - max_vel*accel_dur)/max_vel;    % Duration of ramp
hold_dur = 1;                                         % Duration of hold
f_rest_dur = 2.0;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         %%% TIME SEGMENTS %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
t_rest = 0:dt:init_rest_dur;                                         % Time segment for initial rest
t_acc = (t_rest(end) + dt):dt:(t_rest(end) + dt + accel_dur);        % " " for 1st accel.
t_ramp = (t_acc(end) + dt):dt:(t_acc(end) + dt + ramp_dur);          % " " for const. vel. ramp
t_dec = (t_ramp(end) + dt):dt:(t_ramp(end) + dt + decel_dur);        % " " for 1st decel.
t_hold = (t_dec(end) + dt):dt:(t_dec(end) + dt + hold_dur);          % " " for hold
t_dec2 = (t_hold(end) + dt):dt:(t_hold(end) + dt + decel_dur);       % " " for 2nd decel.
t_rampdown = (t_dec2(end) + dt):dt:(t_dec2(end) + dt + ramp_dur);    % " " for const. vel rampdown  
t_acc2 = (t_rampdown(end) + dt):dt:(t_rampdown(end) + dt + accel_dur);% " " for 2nd accel.
t_rest2 = (t_acc2(end) + dt):dt:(t_acc2(end) + dt + f_rest_dur);      % " " for final rest

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%% LENGTH SEGMENTS %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%% Generate length segments for corresponding  time segments %%%
len_rest = init_len*ones(1,length(t_rest)); 
len_acc = 0.5*max_acc*(t_acc-t_acc(1)).^2 + init_len; 
len_ramp = (max_vel*(t_ramp-t_acc(end)) + len_acc(end)); 
len_decel = 0.5*-max_acc*(t_dec-t_ramp(end)).^2 + max_vel*(t_dec-t_ramp(end)) + len_ramp(end);
len_hold = len_decel(end)*ones(1,length(t_hold));
len_decel2 = 0.5*-max_acc*(t_dec2-t_hold(end)).^2 + len_hold(end);
len_rampdown = -max_vel*(t_rampdown-t_dec2(end)) + len_decel2(end);
len_acc2 = 0.5*max_acc*(t_acc2-t_rampdown(end)).^2 - max_vel*(t_acc2-t_rampdown(end)) + len_rampdown(end);
len_rest2 = len_acc2(end)*ones(1,length(t_rest2));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
       %%% VELOCITY SEGMENTS %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%% Generate velocity segments for corresponding time segments %%%
vel_rest = zeros(1,length(t_rest));
vel_acc = max_acc*(t_acc-t_acc(1));
vel_ramp = max_vel*ones(1,length(t_ramp));
vel_decel = -max_acc*(t_dec-t_dec(1))+max_vel;
vel_hold = zeros(1,length(t_hold));
vel_decel2 = -max_acc*(t_dec2-t_dec2(1));
vel_rampdown = -max_vel*ones(1,length(t_rampdown));
vel_acc2 = max_acc*(t_acc2-t_acc2(1))-max_vel;
vel_rest2 = zeros(1,length(t_rest2));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      %%% ACCELERATION SEGMENTS %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%% Generate acceleration segments for corresponding time segments %%
acc_rest = zeros(1,length(t_rest));
acc_acc = max_acc*ones(1,length(t_acc));
acc_ramp = zeros(1,length(t_ramp));
acc_decel = -max_acc*ones(1,length(t_dec));
acc_hold = zeros(1,length(t_hold));
acc_decel2 = -max_acc*ones(1,length(t_dec2));
acc_rampdown = zeros(1,length(t_rampdown));
acc_acc2 = max_acc*ones(1,length(t_acc2));
acc_rest2 = zeros(1,length(t_rest2));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      %%% GENERATE LEN,VEL,ACC %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if rampdown == 0 % Ramp and hold
    t = 0:dt:t_hold(end); % Total time variable
    len = [len_rest len_acc len_ramp len_decel len_hold]; % Concatenate length segments
    vel = [vel_rest vel_acc vel_ramp vel_decel vel_hold]; % " " velocity segments
    acc = [acc_rest acc_acc acc_ramp acc_decel acc_hold]; % " " acceleration segments
elseif rampdown == 1 % Ramp and hold and return
    t = 0:dt:t_rest2(end); % Total time variable
    len = [len_rest len_acc len_ramp len_decel len_hold len_decel2 len_rampdown len_acc2 len_rest2]; % Concatenate length segments
    vel = [vel_rest vel_acc vel_ramp vel_decel vel_hold vel_decel2 vel_rampdown vel_acc2 vel_rest2]; % " " velocity segments
    acc = [acc_rest acc_acc acc_ramp acc_decel acc_hold acc_decel2 acc_rampdown acc_acc2 acc_rest2]; % " " acceleration segments
end

