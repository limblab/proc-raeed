function [handle] = plotFlatTuning(pdData,curve,maxRadius,color,linspec, move_corrIn)
% PLOTFLATTUNING makes a single figure showing the tuning curve and PD with
% confidence intervals, unwrapped. Leave either entry blank to skip plotting it. Color
% is a 3 element vector for the color of the plotted tuning curve and PD.
% pdData is one row taken from binnedData object.
move_cor = 'velDir';
if nargin >5, move_cor = move_corrIn; end 

hold on

if ~exist('linspec','var') || isempty(linspec)
    linspec = '-';
end

% tuning curve
bins = curve.bins;
if(~isempty(curve))
    if(height(curve)>1)
        error('plotTuning:TooManyThings','curve must contain only one row')
    end
    th_fill = [bins(end)-2*pi bins fliplr(bins) bins(end)-2*pi];
    r_fill = [curve.CIhigh(end) curve.CIhigh fliplr(curve.CIlow) curve.CIlow(end)];
    % h=plot(th_fill,r_fill);
    % set(h,'linewidth',1.2,'color',color)
    h=patch(th_fill,r_fill,color,'edgealpha',0,'facealpha',0.3);
    h=plot([bins(end)-2*pi bins],[curve.binnedResponse(end) curve.binnedResponse]);
    set(h,'linewidth',2,'color',color)
end

% PD
if(~isempty(pdData))
    if(height(pdData)>1)
        error('plotTuning:TooManyThings','pdData must contain only one row')
    end
    % handle wraparound
    if pdData.([move_cor 'CI'])(2)<pdData.([move_cor 'CI'])(1)
        pdData.([move_cor 'CI'])(2) = pdData.([move_cor 'CI'])(2) + 2*pi;
    end
    th_fill = [pdData.([move_cor, 'CI'])(1) pdData.([move_cor, 'CI'])(1) pdData.([move_cor, 'CI'])(2) pdData.([move_cor, 'CI'])(2)];
    r_fill = [0 maxRadius maxRadius 0];
    % h=plot(th_fill,r_fill);
    % set(h,'linewidth',1.2,'color',color)
    h=patch(th_fill,r_fill,color,'edgealpha',0,'facealpha',0.3);
    % plot wraparound
    % h=plot(th_fill-2*pi,r_fill);
    % set(h,'linewidth',1.2,'color',color)
    h=patch(th_fill-2*pi,r_fill,color,'edgealpha',0,'facealpha',0.3);
    h=plot(repmat(pdData.(move_cor),2,1),maxRadius*[0;1],linspec);
    set(h,'linewidth',2,'color',color)
end

set(gca,'xlim',[-pi pi],'ylim',[0 maxRadius],'xtick',[-pi, 0, pi],'xticklabel',{'-\pi','0','\pi'})
