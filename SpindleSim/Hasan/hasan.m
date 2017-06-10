% Created 2013/05 by Kyle P. Blum

function [t,mu,dmudt,r] = hasan(a,b,c,h,p,g,offset,t_x,dxdt,x)
% [t,mu,dmudt,r] = hasan(a,b,c,h,p,g,offset,t_x,dxdt,x)
% This function contains the differential equation and solver for the Hasan
% 1983 muscle spindle model. Inputs include model parameters 
% (a,b,c,h,p,g,offset) and model inputs (t_x, dxdt, x). This function uses
% ODE23s to solve the differential equation. 


%% Solve Differential equation
 
IC = 0.1259;                                       % Initial condition for mu(t) (this was chosen arbitrarily)
tspan = linspace(t_x(1),t_x(end),length(x));       % timespan for ode solver

[t,mu] = ode23s(@(t,mu) myode(t,mu,t_x,x,dxdt,a,b,c),tspan,IC(1)); % Solve ODE
[dmudt] = myode(t,mu,t_x,x,dxdt,a,b,c);                            % Calculate dmu/dt for firing rate

r = h.*(g*(mu+offset) + p.*dmudt);              % Firing rate equation

end
function dmudt = myode(t,mu,t_x,x,dxdt,a,b,c)
% This function is for the ODE solver. It takes several
% inputs and returns dmudt (based on Hasan paper) to the ODE solver. 
x = interp1(t_x,x,t);
dxdt = interp1(t_x,dxdt,t);
dmudt = dxdt - a.*((b.*mu - x + c)./(x - mu - c)).^3;
end




