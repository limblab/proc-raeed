function isTuned = checkIsTuned(pdData,params)
% Check whether PD is tuned.
% params - 
%   .move_corr - movment correlate preceding PDCI in pdData to check (default: 'vel')
%   .CIthresh - maximum CI width (in radians) to be tuned (default: pi/4)

move_corr = 'vel';
CIthresh = pi/4;

if nargin > 1, assignParams(who,params); end % overwrite parameters

CIwidth = diff(pdData.([move_corr 'PDCI']),1,2);
while any(CIwidth<0)
    CIwidth(CIwidth<0) = CIwidth(CIwidth<0)+2*pi;
end

isTuned = CIwidth < CIthresh;
