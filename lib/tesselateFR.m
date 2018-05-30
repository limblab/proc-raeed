function tesselateFR(x,y,fr)
% create patched voronoi diagram with given firing rate

if size(fr,2)>1
    error('Too many firing rates, only one at a time')
end

[v,c] = voronoin([x y]);

for i = 1:length(c)
    if all(c{i}~=1)
        patch(v(c{i},1),v(c{i},2),fr(i))
    end
end

clims = prctile(fr,[5 95]);
caxis(clims)
axis equal

colorbar
