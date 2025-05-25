% File: Drone_Urban_Logistics_Platform/+path_planning_algorithms/+simulated_annealing_vrp/+visualizer_SA/plot_SA_Route_Snapshot.m
function fig = plot_SA_Route_Snapshot(solution, locations, numSelectedHubs, demands, droneParams, utils, plotTitle, savePath)
% Plots the current SA solution (set of routes) at a snapshot in time.
%
% INPUTS:
%   solution (cell array): Current set of routes.
%   locations (Nx2 matrix): Coordinates.
%   numSelectedHubs (integer): Number of active hubs.
%   demands (vector): Customer demands (for display/tooltip if needed, not used directly in plot lines yet).
%   droneParams (struct): Drone parameters (for checking feasibility display if needed).
%   utils (struct): Utility functions.
%   plotTitle (string): Title for the plot.
%   savePath (string, optional): Full path to save the figure. If empty, figure is not saved.

    if nargin < 8, savePath = []; end
    if nargin < 7 || isempty(plotTitle), plotTitle = 'SA Route Snapshot'; end

    fig = figure('Name', plotTitle, 'Visible', 'off', 'Position', [100, 100, 1000, 800]);

    hubsLat = locations(1:numSelectedHubs, 1);
    hubsLon = locations(1:numSelectedHubs, 2);
    customersLat = locations(numSelectedHubs+1:end, 1);
    customersLon = locations(numSelectedHubs+1:end, 2);
    
    useGeoPlot = license('test', 'MAP_Toolbox') && ~isempty(hubsLat); % Check if Mapping Toolbox is available and there's data

    if useGeoPlot
        try
            ax = geoaxes(fig);
            geobasemap(ax, 'streets-light');
            hold(ax, 'on');

            % Plot Hubs
            geoplot(ax, hubsLat, hubsLon, '^k', 'MarkerSize', 10, 'MarkerFaceColor', 'm', 'DisplayName', 'Hubs');
            % Plot Customers
            if ~isempty(customersLat)
                geoplot(ax, customersLat, customersLon, 'ob', 'MarkerSize', 6, 'MarkerFaceColor', 'c', 'DisplayName', 'Customers');
            end

            numValidRoutesToPlot = 0;
            if ~isempty(solution)
                validRoutes = solution(cellfun(@(r) ~isempty(r) && length(r) > 2, solution));
                numValidRoutesToPlot = length(validRoutes);
            end

            if numValidRoutesToPlot > 0
                colors = lines(numValidRoutesToPlot); % Distinct colors for routes
                routeCounter = 0;
                for r = 1:length(solution)
                    route = solution{r};
                    if isempty(route) || length(route) <= 2, continue; end
                    routeCounter = routeCounter + 1;
                    
                    routeCoords = locations(route, :);
                    geoplot(ax, routeCoords(:,1), routeCoords(:,2), 'LineWidth', 1.5, ...
                            'Color', colors(routeCounter,:), 'DisplayName', sprintf('Route %d', routeCounter));
                end
            end
            hold(ax, 'off');
            legend(ax, 'show', 'Location', 'bestoutside');
            
            % Set map limits
            allLats = locations(:,1); allLons = locations(:,2);
            if ~isempty(allLats)
                paddingLat = (max(allLats)-min(allLats))*0.1 + 0.005;
                paddingLon = (max(allLons)-min(allLons))*0.1 + 0.005;
                geolimits(ax, [min(allLats)-paddingLat, max(allLats)+paddingLat], ...
                              [min(allLons)-paddingLon, max(allLons)+paddingLon]);
            end

        catch ME_map
            warning('plot_SA_Route_Snapshot:MapToolboxError', 'Mapping Toolbox error: %s. Using basic plot.', ME_map.message);
            plotBasicScatter();
        end
    else
        % disp('Mapping Toolbox not found or no hub data. Using basic scatter plot for SA routes.');
        plotBasicScatter();
    end
    
    title(plotTitle, 'Interpreter', 'none'); % This is the main title
    % REMOVED SGTITLE: sgtitle(fig, ['Algorithm: Simulated Annealing | ', plotTitle], 'Interpreter', 'none'); 

    if ~isempty(savePath)
        try
            common_utilities.save_Figure_Properly(fig, savePath); % Assumes this utility exists
        catch ME_save
             fprintf('Error saving SA snapshot figure: %s\n', ME_save.message);
        end
    end
    if ~nargout % If no output argument, make visible or close
        set(fig, 'Visible', 'on'); 
        % close(fig); % Or close after saving if running many iterations
    end

    function plotBasicScatter()
        clf(fig); % Clear figure for basic plot
        ax_basic = axes(fig);
        hold(ax_basic, 'on');
        plot(ax_basic, hubsLon, hubsLat, '^k', 'MarkerSize', 10, 'MarkerFaceColor', 'm', 'DisplayName', 'Hubs');
        if ~isempty(customersLon)
            plot(ax_basic, customersLon, customersLat, 'ob', 'MarkerSize', 6, 'MarkerFaceColor', 'c', 'DisplayName', 'Customers');
        end
        
        numValidRoutesToPlot = 0;
        if ~isempty(solution)
            validRoutes = solution(cellfun(@(r) ~isempty(r) && length(r) > 2, solution));
            numValidRoutesToPlot = length(validRoutes);
        end

        if numValidRoutesToPlot > 0
            colors = lines(numValidRoutesToPlot);
            routeCounter = 0;
            for r_idx = 1:length(solution)
                route = solution{r_idx};
                if isempty(route) || length(route) <= 2, continue; end
                routeCounter = routeCounter + 1;
                routeCoords = locations(route, :);
                plot(ax_basic, routeCoords(:,2), routeCoords(:,1), 'LineWidth', 1.5, ...
                     'Color', colors(routeCounter,:), 'DisplayName', sprintf('Route %d', routeCounter));
            end
        end
        hold(ax_basic, 'off');
        xlabel(ax_basic, 'Longitude'); ylabel(ax_basic, 'Latitude');
        legend(ax_basic, 'show', 'Location', 'bestoutside');
        axis(ax_basic, 'equal'); grid(ax_basic, 'on');
    end
end