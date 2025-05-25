% File: Drone_Urban_Logistics_Platform/+comparative_analytics/plot_SA_vs_ACO_Convergence.m
function fig = plot_SA_vs_ACO_Convergence(sa_costHistory, aco_costHistory, plotTitle, savePath)
% Plots the convergence curves of SA and ACO on the same graph.
%
% INPUTS:
%   sa_costHistory (vector): Cost history from the SA algorithm.
%   aco_costHistory (vector): Cost history from the ACO algorithm.
%   plotTitle (string): Title for the plot.
%   savePath (string, optional): Full path to save the figure. If empty, figure is not saved.

    if nargin < 4, savePath = []; end
    if nargin < 3 || isempty(plotTitle)
        plotTitle = 'SA vs. ACO Convergence Comparison';
    end

    fig = figure('Name', 'Algorithm Convergence Comparison', 'Visible', 'off', 'Position', [100, 100, 900, 600]);
    hold on;

    % Plot SA Convergence
    if ~isempty(sa_costHistory)
        plot(1:length(sa_costHistory), sa_costHistory, 'LineWidth', 1.5, 'DisplayName', 'Simulated Annealing (SA)', 'Color', [0 0.4470 0.7410]); % Blue
    else
        warning('plot_SA_vs_ACO_Convergence:NoSAData', 'SA cost history is empty. Skipping SA plot.');
    end

    % Plot ACO Convergence
    if ~isempty(aco_costHistory)
        plot(1:length(aco_costHistory), aco_costHistory, 'LineWidth', 1.5, 'DisplayName', 'Ant Colony Optimization (ACO)', 'Color', [0.8500 0.3250 0.0980]); % Orange
    else
        warning('plot_SA_vs_ACO_Convergence:NoACOData', 'ACO cost history is empty. Skipping ACO plot.');
    end

    hold off;

    xlabel('Iteration Count');
    ylabel('Best Solution Cost');
    title(plotTitle, 'Interpreter', 'none');
    legend('show', 'Location', 'northeast');
    grid on;
    
    % Determine common y-axis limits if both plotted, consider log scale
    allCosts = [];
    if ~isempty(sa_costHistory), allCosts = [allCosts; sa_costHistory(:)]; end
    if ~isempty(aco_costHistory), allCosts = [allCosts; aco_costHistory(:)]; end
    
    if ~isempty(allCosts)
        minCost = min(allCosts);
        maxCost = max(allCosts);
        if minCost > 0 && maxCost > 0 && (maxCost / minCost) > 100
            set(gca, 'YScale', 'log');
            ylabel('Best Solution Cost (log scale)');
        elseif maxCost > minCost % Ensure some sensible y-limits
            ylim([minCost - 0.1*abs(minCost) maxCost + 0.1*abs(maxCost)]);
        end
    end
    
    % Adjust x-axis if lengths are very different - for now, simple plot
    % For a fairer comparison if iteration "granularity" is different,
    % one might need to plot against computation time (if available for each point)
    % or normalize iterations if a "major" iteration concept exists for both.

    if ~isempty(savePath)
        try
            % Assuming common_utilities.save_Figure_Properly exists
            common_utilities.save_Figure_Properly(fig, savePath);
        catch ME_save
             fprintf('Error saving SA vs ACO convergence figure: %s\n', ME_save.message);
        end
    end

    if ~nargout % If no output argument, make visible or close
        set(fig, 'Visible', 'on');
    end
end