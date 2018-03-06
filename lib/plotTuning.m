function [handle] = plotTuning(pdData,curve,maxRadius,color,linspec, move_corrIn)
% PLOT_TUNING makes a single figure showing the tuning curve and PD with
% confidence intervals. Leave either entry blank to skip plotting it. Color
% is a 3 element vector for the color of the plotted tuning curve and PD.
% pdData is one row taken from binnedData object.
move_cor = 'velDir';
if nargin >5, move_cor = move_corrIn; end 
% plot initial point
h=polar(0,maxRadius);
set(h,'color','w')
hold all

if ~exist('linspec','var') || isempty(linspec)
    linspec = '-';
end

% tuning curve
bins = curve.bins;
if(~isempty(curve))
    if(height(curve)>1)
        error('plotTuning:TooManyThings','curve must contain only one row')
    end
    h=polar(repmat(bins,1,2),repmat(curve.binnedResponse,1,2));
    set(h,'linewidth',2,'color',color)
    th_fill = [fliplr(bins) bins(end) bins(end) bins];
    r_fill = [fliplr(curve.CIhigh) curve.CIhigh(end) curve.CIlow(end) curve.CIlow];
    [x_fill,y_fill] = pol2cart(th_fill,r_fill);
    patch(x_fill,y_fill,color,'facealpha',0.3,'edgealpha',0);
end

% PD
if(~isempty(pdData))
    if(height(pdData)>1)
        error('plotTuning:TooManyThings','pdData must contain only one row')
    end
    h=polar(repmat(pdData.(move_cor),2,1),maxRadius*[0;1],linspec);
    set(h,'linewidth',2,'color',color)
    th_fill = [pdData.([move_cor, 'CI'])(2) pdData.(move_cor) pdData.([move_cor, 'CI'])(1) 0];
    r_fill = [maxRadius maxRadius maxRadius 0];
    [x_fill,y_fill] = pol2cart(th_fill,r_fill);
    patch(x_fill,y_fill,color,'edgecolor','none','facealpha',0.3);
end
