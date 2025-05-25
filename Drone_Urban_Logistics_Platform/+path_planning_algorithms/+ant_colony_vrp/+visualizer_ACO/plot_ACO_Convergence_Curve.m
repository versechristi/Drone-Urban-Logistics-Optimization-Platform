% File: Drone_Urban_Logistics_Platform/+path_planning_algorithms/+ant_colony_vrp/+visualizer_ACO/plot_ACO_Convergence_Curve.m
function fig = plot_ACO_Convergence_Curve(costHistory, plotTitle, savePath)
% Plots the ACO convergence curve (cost vs. iteration).
%
% INPUTS:
%   costHistory (vector): Cost of the best-so-far solution at each iteration.
%   plotTitle (string): Title for the plot.
%   savePath (string, optional): Full path to save the figure.

    if nargin < 3, savePath = []; end
    if nargin < 2 || isempty(plotTitle), plotTitle = 'ACO Convergence Curve'; end

    fig = figure('Name', plotTitle, 'Visible', 'off', 'Position', [250, 250, 800, 600]); % Slightly offset
    
    plot(1:length(costHistory), costHistory, 'LineWidth', 1.5, 'Color', [0.8500 0.3250 0.0980]); % Orange color
    xlabel('Iteration');
    ylabel('Best Global Cost Found');
    title(plotTitle, 'Interpreter', 'none'); % This is the main title
    grid on;
    
    if ~isempty(costHistory) && min(costHistory) > 0 && (max(costHistory) / min(costHistory)) > 100 % Added ~isempty(costHistory) check
        set(gca, 'YScale', 'log');
        ylabel('Best Global Cost Found (log scale)');
    end

    % REMOVED SGTITLE: sgtitle(fig, ['Algorithm: Ant Colony Optimization | ', plotTitle], 'Interpreter', 'none');

    if ~isempty(savePath)
        try
            common_utilities.save_Figure_Properly(fig, savePath);
        catch ME_save
            fprintf('Error saving ACO convergence figure: %s\n', ME_save.message);
        end
    end
    if ~nargout
        set(fig, 'Visible', 'on');
        % close(fig);
    end
end