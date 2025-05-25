% File: Drone_Urban_Logistics_Platform/+path_planning_algorithms/+ant_colony_vrp/+visualizer_ACO/plot_ACO_Route_Snapshot.m
function fig = plot_ACO_Route_Snapshot(solution, locations, numSelectedHubs, demands, droneParams, utils, plotTitle, savePath)
% Plots the current ACO solution (set of routes) at a snapshot in time.
%
% INPUTS:
%   solution (cell array): Current set of routes.
%   locations (Nx2 matrix): Coordinates.
%   numSelectedHubs (integer): Number of active hubs.
%   demands (vector): Customer demands.
%   droneParams (struct): Drone parameters.
%   utils (struct): Utility functions.
%   plotTitle (string): Title for the plot.
%   savePath (string, optional): Full path to save the figure.

    if nargin < 8, savePath = []; end
    if nargin < 7 || isempty(plotTitle), plotTitle = 'ACO Route Snapshot'; end

    fig = figure('Name', plotTitle, 'Visible', 'off', 'Position', [150, 150, 1000, 800]); % Slightly offset from SA plots

    hubsLat = locations(1:numSelectedHubs, 1);
    hubsLon = locations(1:numSelectedHubs, 2);
    customersLat = locations(numSelectedHubs+1:end, 1);
    customersLon = locations(numSelectedHubs+1:end, 2);
    
    useGeoPlot = license('test', 'MAP_Toolbox') && ~isempty(hubsLat);

    if useGeoPlot
        try
            ax = geoaxes(fig);
            geobasemap(ax, 'satellite'); % Different basemap for visual distinction
            hold(ax, 'on');

            geoplot(ax, hubsLat, hubsLon, '^k', 'MarkerSize', 10, 'MarkerFaceColor', 'y', 'DisplayName', 'Hubs'); % Yellow hubs for ACO
            if ~isempty(customersLat)
                geoplot(ax, customersLat, customersLon, 'ob', 'MarkerSize', 6, 'MarkerFaceColor', 'g', 'DisplayName', 'Customers'); % Green customers
            end

            numValidRoutesToPlot = 0;
            if ~isempty(solution)
                validRoutes = solution(cellfun(@(r) ~isempty(r) && length(r) > 2, solution));
                numValidRoutesToPlot = length(validRoutes);
            end
            
            if numValidRoutesToPlot > 0
                colors = winter(numValidRoutesToPlot); % Different color scheme
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
            
            allLats = locations(:,1); allLons = locations(:,2);
            if ~isempty(allLats)
                paddingLat = (max(allLats)-min(allLats))*0.1 + 0.005;
                paddingLon = (max(allLons)-min(allLons))*0.1 + 0.005;
                geolimits(ax, [min(allLats)-paddingLat, max(allLats)+paddingLat], ...
                              [min(allLons)-paddingLon, max(allLons)+paddingLon]);
            end
        catch ME_map
             warning('plot_ACO_Route_Snapshot:MapToolboxError', 'Mapping Toolbox error: %s. Using basic plot.', ME_map.message);
            plotBasicScatter();
        end
    else
        plotBasicScatter();
    end
    
    title(plotTitle, 'Interpreter', 'none'); % This is the main title
    % REMOVED SGTITLE: sgtitle(fig, ['Algorithm: Ant Colony Optimization | ', plotTitle], 'Interpreter', 'none');

    if ~isempty(savePath)
        try
            common_utilities.save_Figure_Properly(fig, savePath);
        catch ME_save
             fprintf('Error saving ACO snapshot figure: %s\n', ME_save.message);
        end
    end
     if ~nargout
        set(fig, 'Visible', 'on');
        % close(fig);
    end

    function plotBasicScatter()
        clf(fig);
        ax_basic = axes(fig);
        hold(ax_basic, 'on');
        plot(ax_basic, hubsLon, hubsLat, '^k', 'MarkerSize', 10, 'MarkerFaceColor', 'y', 'DisplayName', 'Hubs');
        if ~isempty(customersLon)
            plot(ax_basic, customersLon, customersLat, 'ob', 'MarkerSize', 6, 'MarkerFaceColor', 'g', 'DisplayName', 'Customers');
        end
        
        numValidRoutesToPlot = 0;
        if ~isempty(solution)
            validRoutes = solution(cellfun(@(r) ~isempty(r) && length(r) > 2, solution));
            numValidRoutesToPlot = length(validRoutes);
        end

        if numValidRoutesToPlot > 0
            colors = winter(numValidRoutesToPlot);
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