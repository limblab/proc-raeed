function plotFlatTuning(pdData,curve,maxRadius,color,linspec, move_corrIn)
% PLOTFLATTUNING makes a single figure showing the tuning curve and PD with
% confidence intervals, unwrapped. Leave either entry blank to skip plotting it. Color
% is a 3 element vector for the color of the plotted tuning curve and PD.
% pdData is one row taken from binnedData object.
move_cor = 'vel';
if nargin >5, move_cor = move_corrIn; end 

hold on

if ~exist('linspec','var') || isempty(linspec)
    linspec = '-';
end

% tuning curve
if(~isempty(curve))
    if(height(curve)>1)
        error('plotTuning:TooManyThings','curve must contain only one row')
    end
    bins = curve.bins;
    th_wrap = [bins-2*pi bins bins+2*pi];
    th_fill = [th_wrap fliplr(th_wrap)];
    r_fill = [repmat(curve.(sprintf('%sCurveCIlow',move_cor)),1,3) fliplr(repmat(curve.(sprintf('%sCurveCIhigh',move_cor)),1,3))];
    th_fill = th_fill(~isnan(r_fill));
    r_fill = r_fill(~isnan(r_fill));
    % h=plot(th_fill,r_fill);
    % set(h,'linewidth',1.2,'color',color)
    patch(th_fill,r_fill,color,'edgealpha',0,'facealpha',0.3);
    curve_wrap = repmat(curve.(sprintf('%sCurve',move_cor)),1,3);
    th_wrap = th_wrap(~isnan(curve_wrap));
    curve_wrap = curve_wrap(~isnan(curve_wrap));
    plot(th_wrap,curve_wrap,'linewidth',2,'color',color);
end

% PD
if(~isempty(pdData))
    if(height(pdData)>1)
        error('plotTuning:TooManyThings','pdData must contain only one row')
    end
    % handle wraparound
    if pdData.([move_cor 'PDCI'])(2)<pdData.([move_cor 'PDCI'])(1)
        pdData.([move_cor 'PDCI'])(2) = pdData.([move_cor 'PDCI'])(2) + 2*pi;
    end
    th_fill = [pdData.([move_cor, 'PDCI'])(1) pdData.([move_cor, 'PDCI'])(1) pdData.([move_cor, 'PDCI'])(2) pdData.([move_cor, 'PDCI'])(2)];
    r_fill = [0 maxRadius maxRadius 0];
    % h=plot(th_fill,r_fill);
    % set(h,'linewidth',1.2,'color',color)
    patch(th_fill,r_fill,color,'edgealpha',0,'facealpha',0.3);
    % plot wraparound
    % h=plot(th_fill-2*pi,r_fill);
    % set(h,'linewidth',1.2,'color',color)
    patch(th_fill-2*pi,r_fill,color,'edgealpha',0,'facealpha',0.3);
    h=plot(repmat(pdData.([move_cor 'PD']),2,1),maxRadius*[0;1],linspec);
    set(h,'linewidth',2,'color',color)
end

set(gca,'box','off','tickdir','out','xlim',[-pi pi],'ylim',[0 maxRadius],'xtick',[-pi, 0, pi],'xticklabel',{'-180','0','180'})
