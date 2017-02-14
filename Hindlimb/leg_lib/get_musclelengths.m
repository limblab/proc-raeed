function lengths = get_musclelengths(legmodel,q)
% get muscle lengths from base leg and provided angles

%% Get world points
[~,oiv_world] = get_legpts(legmodel,q);

%% Extract necessary muscle lengths
lengths = zeros(1,length(oiv_world));

for musc_idx = 1:length(oiv_world)
    % Sum world OIVs for muscle lengths
    oiv = oiv_world{musc_idx};
    for oiv_idx = 2:size(oiv,1)
        seg_length = sqrt(sum( (oiv_world{musc_idx}(oiv_idx,:)-oiv_world{musc_idx}(oiv_idx-1,:)).^2 ));
        lengths(musc_idx) = lengths(musc_idx) + seg_length;
    end
end
