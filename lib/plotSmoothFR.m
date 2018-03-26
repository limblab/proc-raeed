function plotSmoothFR(x,y,fr,gridrange)
% create smoothed FR plot over variables x and y

if size(fr,2)>1
    error('Too many firing rates, only one at a time')
end

x_cent = x-mean(x);
y_cent = y-mean(y);
if ~exist('gridrange','var')
    gridrange = [min(min([x_cent,y_cent])) max(max([x_cent,y_cent]))];
end

[xq,yq] = meshgrid(linspace(gridrange(1),gridrange(2),100));

fr_grid = griddata(x_cent,y_cent,fr,xq,yq,'natural');
scatter(xq(:)+mean(x),yq(:)+mean(y),10,fr_grid(:),'filled')
% mesh(xq,yq,fr_grid)
% imagesc(fr_grid)

clims = prctile(fr,[5 95]);
caxis(clims)
axis equal

colorbar

