function [fr,thv,thf] = obs_window_pds(cds)

% set window radius
Wr = 3;

% extract time and position signals
t = cds.kin.t;
tf = cds.force.t;
if(sum(tf~=t)>0)
    error('Mismatch between kin times and force times')
end
x = [cds.kin.x cds.kin.y] - repmat([0 -32], size(t,1), 1);
f = [cds.force.fx cds.force.fy];

% extract trajectories through observation window
Wf = x(:,1).^2 + x(:,2).^2 < Wr.^2;
iStart = find(diff(Wf)>0);
iStop  = find(diff(Wf)<0); 

% A little Kluge to eleminate any partial trajectories at the beginning or
% end of the file
if iStart(1) > iStop(1)
    iStop = iStop(2:end);
end

if length(iStart) > length(iStop)
    iStart = iStart(1:length(iStop));
end

% Select the paths that we're going to use
lMin = 3; % minimum path length
maxLenRat = 1.5; % maximum ratio of displacement to path length
kMax = 2; % maximum peak curvature

keepers = true(size(iStart));
for i = 1:length(keepers)
    snip = x(iStart(i):iStop(i), :);
    
    % Reject paths that are too short
    steps = diff(snip);
    len = sum(sqrt(steps(:,1).^2+steps(:,2).^2));
    keepers(i) = keepers(i) & len > lMin; 
    
    % Reject paths that have too high a length to displacement ratio
    dist = sqrt( (snip(end,1)-snip(1,1)).^2 + (snip(end,2)-snip(1,2)).^2 );
    keepers(i) = keepers(i) & len/dist < maxLenRat;
    
    % Reject paths that have too high a peak curvature
    k = curvature(snip);
    if(isempty(k))
        k=inf;
    end
    keepers(i) = keepers(i) & max(abs(k)) < kMax;
    
    % Reject paths that occur outside of a trial
%     trialSuccess = cds.trials(srcmp(cds.trials.result,'R'),:);
    logicalTrialNum = cds.trials.startTime<t(iStart(i)) & cds.trials.endTime>t(iStart(i)) & cds.trials.startTime<t(iStop(i)) & cds.trials.endTime>t(iStop(i));
    keepers(i) = sum(logicalTrialNum)==1;
end

% Plot all paths to inspect our selection algorithm
figure; hold on;
cols = {'r-', 'b-'};
for i = 1:length(iStart)
    snipx = x(iStart(i):iStop(i), 1);
    snipy = x(iStart(i):iStop(i), 2);
    box = ceil(i/5);
    offsetx = 2*Wr*mod(box,10);
    offsety = 2*Wr*ceil(box/10);
    plot(snipx + offsetx, snipy + offsety, cols{keepers(i)+1});
    th = 0:.01:2*pi;
    plot(Wr*cos(th)+offsetx, Wr*sin(th)+offsety, 'Color', [.5 .5 .5]);
end
axis equal;
axis off;

% Dump all the rejected trajectories
iStart = iStart(keepers);
iStop = iStop(keepers);

% extract thv and thf
thv = zeros(length(iStart),1);
thf = zeros(length(iStart),1);
for i = 1:length(thv)
    snip = x(iStart(i):iStop(i), :);
    thv(i) = atan2( mean(gradient(snip(:,2))), mean(gradient(snip(:,1))) );
    thf(i) = atan2( mean(f(iStart(i):iStop(i),2)), mean(f(iStart(i):iStop(i),1)) );
end
figure;plot(thf,thv,'o')
set(gca,'box','off','tickdir','out','xtick',[-pi 0 pi],'ytick',[-pi 0 pi],'xticklabel',{'-\pi','0','\pi'},'yticklabel',{'-\pi','0','\pi'})
xlabel('Force Direction')
ylabel('Velocity Direction')
fr = [];

% Plot the tuning curves
% fr = zeros(length(iStart),length(unit_list(cds)));
% for uid = 1:length(unit_list(cds))
%     thv = zeros(length(iStart),1);
%     thf = zeros(length(iStart),1);
%     la = zeros(size(thv));
%     s = cds.units(uid).ts;
%     for i = 1:length(thv)
%         snip = x(iStart(i):iStop(i), :);
%         thv(i) = atan2( mean(gradient(snip(:,2))), mean(gradient(snip(:,1))) );
%         thf(i) = atan2( mean(f(iStart(i):iStop(i),2)), mean(f(iStart(i):iStop(i),1)) );
%         la(i) = sum(s < t(iStop(i)) & s > t(iStart(i))) / (iStop(i)-iStart(i)) * 1000;
%     end
%     fr(:,uid) = la;
% 
%     %phi = pi/2; % cutoff plane to separate movements
%     %vdf = thv < phi & thv > (phi - pi); % velocity direction filter
% 
% %     [xx, yy] = meshgrid(-pi:pi/10:pi, -pi:pi/10:pi);
% %     gx = zeros(size(xx));
% %     gp = zeros(size(xx));
% %     sig = .5;
% %     for offsetx = -2:2
% %         for offsety = -2:2
% %             dx = 2*pi*offsetx;
% %             dy = 2*pi*offsety;
% %             for i = 1:length(thf)
% %                 gx = gx + la(i) * exp( -sqrt((thf(i)-xx-dx).^2 + (thv(i)-yy-dy).^2) / 2 / sig.^2 );
% %                 gp = gp + exp( -sqrt((thf(i)-xx-dx).^2 + (thv(i)-yy-dy).^2) / 2 / sig.^2 );
% %             end
% %         end
% %     end
% %     srf = gx ./ gp;
% % 
% %     figure; plot3(thf, thv, la, 'k.');
% %     hold on;
% %     mesh(xx,yy,srf);
% %     xlabel('Force Direction');
% %     ylabel('Velocity Direction');
% %     zlabel('Firing Rate');
% %     title(sprintf('Neuron %d', uid));
% 
% end % foreach unit
