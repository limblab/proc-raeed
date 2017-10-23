function isTuned = checkIsTuned(pdData,params)
% Check whether PD is tuned.
% params - 
%   .move_corr - movment correlate preceding DirCI in pdData to check (default: 'vel')
%   .CIthresh - maximum CI width (in radians) to be tuned (default: pi/4)

move_corr = 'vel';
CIthresh = pi/4;

if nargin > 1, assignParams(who,params); end % overwrite parameters

CIwidth = minusPi2Pi(diff(pdData.([move_corr 'DirCI']),1,2));
isTuned = CIwidth < pi/4;
