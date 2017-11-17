% load CDS
% load('/Users/mattperich/Data/Chewie_CO_FF_BL_10072016_001.mat')

load('F:\Chewie\CDS\2016-10-06\Chewie_CO_VR_BL_10062016_001.mat')

%%
close all;

% Loop along units and plot mean of all waveforms in the appropriate location
unit_colors = {'k','b','r','g','c','m','y'};
figure; subplot1(10,10);

idx = find(strcmpi({cds.units.array},'M1'));

for i = idx
    if cds.units(i).ID > 0 && cds.units(i).ID ~= 255
        row = cds.units(i).rowNum;
        col = cds.units(i).colNum;
        
        subplot1(10*(row-1)+col); hold all;
        plot(mean(cds.units(i).spikes.wave,1),'-','LineWidth',1,'Color',unit_colors{cds.units(i).ID});
    end
end
for i = 1:10
    for j = 1:10
        subplot1(10*(i-1)+j);
        set(gca,'Box','off','TickDir','out','XTick',[],'YTick',[]);
        ax = gca; 
ax.XAxis.Visible = 'off';
ax.YAxis.Visible = 'off';
        axis('square');
    end
end



figure; subplot1(10,10);
idx = find(strcmpi({cds.units.array},'PMd'));

for i = idx
    if cds.units(i).ID > 0 && cds.units(i).ID ~= 255
        row = cds.units(i).rowNum;
        col = cds.units(i).colNum;
        
        subplot1(10*(row-1)+col); hold all;
        plot(mean(cds.units(i).spikes.wave,1),'-','LineWidth',1,'Color',unit_colors{cds.units(i).ID});
    end
end
for i = 1:10
    for j = 1:10
        subplot1(10*(i-1)+j);
        set(gca,'Box','off','TickDir','out','XTick',[],'YTick',[]);
        ax = gca; 
ax.XAxis.Visible = 'off';
ax.YAxis.Visible = 'off';
        axis('square');
    end
end


disp('Done.');