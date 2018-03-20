function plotSmoothFR(x,y,fr,gridrange)
% create smoothed FR plot over variables x and y

if size(fr,2)>1
    error('Too many firing rates, only one at a time')
end

[xq,yq] = meshgrid(linspace(gridrange(1),gridrange(2),100));

fr_grid = griddata(x,y,fr,xq,yq,'v4');
% scatter(xq(:),yq(:),10,fr_grid(:),'filled')
% surf(xq,yq,fr_grid)
imagesc(fr_grid)

clims = prctile(fr,[5 95]);
caxis(clims)
axis equal

colorbar

