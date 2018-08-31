function plotTensorDecomp(M, params)
% Assumes rank 10 decomposition into M (a ktensor)
    
    % default params
    temporal_zero = 0; % should be num_bins_before+1
    bin_size = 0.01;
    trial_colors = 'k';

    if nargin>1
        assignParams(who,params);
    end

    % Look at signal factors
        signal_factors = M.U{2};
        markervec = 1:size(signal_factors,1);
        figure
        for i = 1:size(signal_factors,2)
            subplot(5,2,i)
            bar(markervec,signal_factors(:,i))
        end

    % Plot temporal factors
        temporal_factors = M.U{1};
        timevec = ((1:size(temporal_factors,1))-temporal_zero)*bin_size;
        figure
        for i = 1:size(temporal_factors,2)
            subplot(5,2,i)
            plot(timevec,temporal_factors(:,i),'-k','linewidth',3)
            hold on
            plot(timevec([1 end]),[0 0],'-k','linewidth',2)
            plot([0 0],ylim,'--k','linewidth',2)
        end

    % Look at trial factors
        trial_factors = M.U{3};
        trialvec = 1:size(trial_factors,1);
        figure
        for i = 1:size(trial_factors,2)
            subplot(5,2,i)
            scatter(trialvec,trial_factors(:,i),[],trial_colors,'filled')
            hold on
            plot(trialvec([1 end]),[0 0],'-k','linewidth',2)
        end
