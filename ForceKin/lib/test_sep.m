function [separability,mdl] = test_sep(td,params)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DEFAULT PARAMETER VALUES
use_trials      =  1:length(td);
signals         =  getTDfields(td,'spikes');
do_plot         =  false;
mdl             =  [];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Some extra parameters you can change that aren't described in header
if nargin > 1, assignParams(who,params); end % overwrite parameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% process and prepare inputs
signals = check_signals(td(1),signals);
if iscell(use_trials) % likely to be meta info
    use_trials = getTDidx(td,use_trials{:});
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
signals = check_signals(td,signals);

% ideally, this would work like trialAverage, where the function would take in a condition
% But...I'm not sure how to deal with more than two values for the condition
[~,td_act] = getTDidx(td,'ctrHoldBump',false);
[~,td_pas] = getTDidx(td,'ctrHoldBump',true);

% clean nans out...?
nanners = isnan(cat(1,td_act.target_direction));
td_act = td_act(~nanners);

signal_act = get_vars(td_act,signals);
signal_pas = get_vars(td_pas,signals);

% Find total separability
signal = cat(1,signal_act,signal_pas);
actpas = [ones(length(signal_act),1);zeros(length(signal_pas),1)];
[train_idx,test_idx] = crossvalind('LeaveMOut',length(actpas),floor(length(actpas)/10));

% get model
if isempty(mdl)
    mdl = fitcdiscr(signal(train_idx,:),actpas(train_idx));
end
class = predict(mdl,signal(test_idx,:));
separability = sum(class == actpas(test_idx))/sum(test_idx);

class_train = predict(mdl,signal(train_idx,:));
sep_train = sum(class_train == actpas(train_idx))/sum(train_idx);



if do_plot
    % plot active as filled, passive as open
    bump_colors = linspecer(4);
    act_dir_idx = floor(cat(1,td_act.target_direction)/(pi/2))+1;
    pas_dir_idx = floor(cat(1,td_pas.bumpDir)/90)+1;
    
    w = mdl.Sigma\diff(mdl.Mu)';
    signal_sep = signal*w;

    % get basis vector orthogonal to w for plotting
    null_sep = null(w');
    signal_null_sep = signal*null_sep;
    [~,signal_null_sep_scores] = pca(signal_null_sep);

    figure
    % plot twice to get two separate views
    % first for act/pas separability
    subplot(1,2,1)
    hold all
    scatter3(signal_sep(actpas==1),signal_null_sep_scores(actpas==1,1),signal_null_sep_scores(actpas==1,2),50,bump_colors(act_dir_idx,:),'filled')
    scatter3(signal_sep(actpas==0),signal_null_sep_scores(actpas==0,1),signal_null_sep_scores(actpas==0,2),100,bump_colors(pas_dir_idx,:),'o','linewidth',2)
    ylim = get(gca,'ylim');
    zlim = get(gca,'zlim');
    plot3([0 0],ylim,[0 0],'--k','linewidth',2)
    plot3([0 0],[0 0],zlim,'--k','linewidth',2)
    set(gca,'box','off','tickdir','out')
    view([0 0])
    axis off
    
    % then for directional separability/other view
    subplot(1,2,2)
    hold all
    scatter3(signal_act(:,1),signal_act(:,2),signal_act(:,3),50,bump_colors(act_dir_idx,:),'filled')
    scatter3(signal_pas(:,1),signal_pas(:,2),signal_pas(:,3),100,bump_colors(pas_dir_idx,:),'o','linewidth',2)
    ylim = get(gca,'ylim');
    zlim = get(gca,'zlim');
    set(gca,'box','off','tickdir','out')
    axis equal
    axis off
end
