function plotTensorDecomp(M, params)
    
    % default params
    temporal_zero = 0; % should be num_bins_before+1
    bin_size = 0.01;
    trial_colors = 'k';

    if nargin>1
        assignParams(who,params);
    end

    figure
    ncol = 3;
    nrow = size(M.U{1},2);

    % Look at signal factors
    signal_factors = M.U{2};
    markervec = 1:size(signal_factors,1);
    for i = 1:size(signal_factors,2)
        subplot(nrow,ncol,(i-1)*ncol+1)
        bar(markervec,signal_factors(:,i))
        set(gca,'box','off','tickdir','out')
    end

    % Plot temporal factors
    temporal_factors = M.U{1};
    timevec = ((1:size(temporal_factors,1))-temporal_zero)*bin_size;
    for i = 1:size(temporal_factors,2)
        subplot(nrow,ncol,(i-1)*ncol+2)
        plot(timevec,temporal_factors(:,i),'-k','linewidth',3)
        hold on
        plot(timevec([1 end]),[0 0],'-k','linewidth',2)
        plot([0 0],ylim,'--k','linewidth',2)
        set(gca,'box','off','tickdir','out')
    end

    % Look at trial factors
    trial_factors = M.U{3};
    trialvec = 1:size(trial_factors,1);
    for i = 1:size(trial_factors,2)
        subplot(nrow,ncol,(i-1)*ncol+3)
        scatter(trialvec,trial_factors(:,i),[],trial_colors,'filled')
        hold on
        plot(trialvec([1 end]),[0 0],'-k','linewidth',2)
        set(gca,'box','off','tickdir','out')
    end
