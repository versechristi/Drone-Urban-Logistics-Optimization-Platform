% File: Drone_Urban_Logistics_Platform/+path_planning_algorithms/+simulated_annealing_vrp/+visualizer_SA/plot_SA_Convergence_Curve.m
function fig = plot_SA_Convergence_Curve(costHistory, plotTitle, savePath)
% Plots the SA convergence curve (cost vs. iteration).
%
% INPUTS:
%   costHistory (vector): Cost of the best-so-far solution at each iteration.
%   plotTitle (string): Title for the plot.
%   savePath (string, optional): Full path to save the figure.

    if nargin < 3, savePath = []; end
    if nargin < 2 || isempty(plotTitle), plotTitle = 'SA Convergence Curve'; end

    fig = figure('Name', plotTitle, 'Visible', 'off', 'Position', [200, 200, 800, 600]);
    
    plot(1:length(costHistory), costHistory, 'LineWidth', 1.5);
    xlabel('Iteration');
    ylabel('Best Cost Found');
    title(plotTitle, 'Interpreter', 'none'); % This is the main title
    grid on;
    
    % Use log scale if cost changes span orders of magnitude and are all positive
    if ~isempty(costHistory) && min(costHistory) > 0 && (max(costHistory) / min(costHistory)) > 100 % Added ~isempty(costHistory) check
        set(gca, 'YScale', 'log');
        ylabel('Best Cost Found (log scale)');
    end
    
    % REMOVED SGTITLE: sgtitle(fig, ['Algorithm: Simulated Annealing | ', plotTitle], 'Interpreter', 'none');

    if ~isempty(savePath)
         try
            common_utilities.save_Figure_Properly(fig, savePath);
        catch ME_save
             fprintf('Error saving SA convergence figure: %s\n', ME_save.message);
        end
    end
    if ~nargout
        set(fig, 'Visible', 'on');
        % close(fig);
    end
end