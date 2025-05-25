% File: Drone_Urban_Logistics_Platform/+comparative_analytics/plot_Final_Performance_Bars.m
function fig = plot_Final_Performance_Bars(sa_finalResults, aco_finalResults, plotTitle, savePath)
% Creates a grouped bar chart comparing final performance metrics of SA and ACO.
%
% INPUTS:
%   sa_finalResults (struct): Struct with SA's final metrics, e.g.,
%                             .Cost, .ComputationTime, .NumRoutes, .TotalDistance
%   aco_finalResults (struct): Struct with ACO's final metrics (same fields).
%   plotTitle (string): Title for the plot.
%   savePath (string, optional): Full path to save the figure.

    if nargin < 4, savePath = []; end
    if nargin < 3 || isempty(plotTitle)
        plotTitle = 'Final Performance Comparison: SA vs. ACO';
    end

    fig = figure('Name', 'Final Performance Comparison', 'Visible', 'off', 'Position', [150, 150, 1000, 700]);

    metricsToCompare = {};
    sa_values = [];
    aco_values = [];

    % Metric 1: Final Cost
    if isfield(sa_finalResults, 'Cost') && isfield(aco_finalResults, 'Cost')
        metricsToCompare{end+1} = 'Final Cost';
        sa_values(end+1) = sa_finalResults.Cost;
        aco_values(end+1) = aco_finalResults.Cost;
    end

    % Metric 2: Computation Time (seconds)
    if isfield(sa_finalResults, 'ComputationTime') && isfield(aco_finalResults, 'ComputationTime')
        metricsToCompare{end+1} = 'Computation Time (s)';
        sa_values(end+1) = sa_finalResults.ComputationTime;
        aco_values(end+1) = aco_finalResults.ComputationTime;
    end

    % Metric 3: Number of Routes
    if isfield(sa_finalResults, 'NumRoutes') && isfield(aco_finalResults, 'NumRoutes')
        metricsToCompare{end+1} = 'Number of Routes';
        sa_values(end+1) = sa_finalResults.NumRoutes;
        aco_values(end+1) = aco_finalResults.NumRoutes;
    end
    
    % Metric 4: Total Distance Traveled (km)
    if isfield(sa_finalResults, 'TotalDistance') && isfield(aco_finalResults, 'TotalDistance')
        metricsToCompare{end+1} = 'Total Distance (km)';
        sa_values(end+1) = sa_finalResults.TotalDistance;
        aco_values(end+1) = aco_finalResults.TotalDistance;
    end

    if isempty(metricsToCompare)
        text(0.5,0.5, 'No comparable metrics found in results.', 'HorizontalAlignment', 'center', 'Parent', axes(fig));
        title(plotTitle);
        if ~isempty(savePath), try common_utilities.save_Figure_Properly(fig, savePath); catch; end; end
        if ~nargout, set(fig, 'Visible', 'on'); end
        return;
    end

    % Data for bar chart: [SA_value_metric1, ACO_value_metric1; SA_value_metric2, ACO_value_metric2; ...]
    barData = [sa_values', aco_values'];

    b = bar(barData);
    b(1).FaceColor = [0 0.4470 0.7410]; % SA - Blue
    b(2).FaceColor = [0.8500 0.3250 0.0980]; % ACO - Orange

    ylabel('Metric Value');
    set(gca, 'XTickLabel', metricsToCompare, 'XTickLabelRotation', 15);
    title(plotTitle, 'Interpreter', 'none');
    legend({'Simulated Annealing (SA)', 'Ant Colony Optimization (ACO)'}, 'Location', 'northeastoutside');
    grid on;
    
    % Add text labels on top of bars
    for i = 1:length(b) % For each algorithm (SA, ACO)
        for j = 1:size(barData,1) % For each metric
            text(j + (i-1.5)*0.15, barData(j,i), sprintf('%.2f', barData(j,i)), ... % Adjust x position for label
                 'HorizontalAlignment','center', 'VerticalAlignment','bottom', 'FontSize', 8);
        end
    end


    if ~isempty(savePath)
        try
            common_utilities.save_Figure_Properly(fig, savePath);
        catch ME_save
            fprintf('Error saving final performance bar chart: %s\n', ME_save.message);
        end
    end

    if ~nargout
        set(fig, 'Visible', 'on');
    end
end