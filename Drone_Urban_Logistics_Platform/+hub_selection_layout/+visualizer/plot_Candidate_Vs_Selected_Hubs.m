% File: Drone_Urban_Logistics_Platform/+hub_selection_layout/+visualizer/plot_Candidate_Vs_Selected_Hubs.m
function fig = plot_Candidate_Vs_Selected_Hubs(candidateDepots, selectedHubs, customers, scenarioParams, plotTitle)
% Plots candidate depots, highlights selected hubs, and optionally shows customers.
%
% INPUTS:
%   candidateDepots (struct array): All candidate depots (.Latitude, .Longitude).
%   selectedHubs (struct array): The selected hubs (.ID, .Latitude, .Longitude).
%   customers (struct array, optional): Customer data (.Latitude, .Longitude).
%   scenarioParams (struct, optional): For map center to aid geobasemap focus.
%                                       (.CenterLatitude, .CenterLongitude)
%   plotTitle (string, optional): Title for the plot.

    if nargin < 5 || isempty(plotTitle)
        plotTitle = 'Candidate Depots and Selected Hubs';
    end
    if nargin < 3
        customers = []; % No customers to plot
    end
     if nargin < 4
        scenarioParams = []; 
    end

    fig = figure('Name', plotTitle, 'Visible', 'off'); % Create figure but keep it invisible initially
    
    if license('test', 'MAP_Toolbox')
        try
            ax = geoaxes();
            geobasemap(ax, 'streets-light'); % or 'satellite', 'topographic'

            % Plot Customers (if provided)
            if ~isempty(customers)
                custLats = [customers.Latitude];
                custLons = [customers.Longitude];
                geoplot(ax, custLats, custLons, '.b', 'MarkerSize', 10, 'DisplayName', 'Customers');
                hold(ax, 'on');
            end

            % Plot Candidate Depots
            if ~isempty(candidateDepots)
                candLats = [candidateDepots.Latitude];
                candLons = [candidateDepots.Longitude];
                geoplot(ax, candLats, candLons, 'ok', 'MarkerSize', 6, ...
                        'MarkerFaceColor', [0.7 0.7 0.7], 'DisplayName', 'Candidate Depots');
                hold(ax, 'on');
            end

            % Plot Selected Hubs
            if ~isempty(selectedHubs)
                selLats = [selectedHubs.Latitude];
                selLons = [selectedHubs.Longitude];
                geoplot(ax, selLats, selLons, '^r', 'MarkerSize', 10, ...
                        'MarkerFaceColor', 'r', 'LineWidth', 1.5, 'DisplayName', 'Selected Hubs');
                
                % Optionally, label selected hubs with their IDs
                % for i = 1:length(selectedHubs)
                %    text(ax, selLons(i) + 0.001, selLats(i), num2str(selectedHubs(i).ID), 'Color', 'red');
                % end
            end
            
            hold(ax, 'off');
            title(ax, plotTitle);
            legend(ax, 'show', 'Location', 'bestoutside');
            
            % Set map limits based on scenario or data
            if ~isempty(scenarioParams) && isfield(scenarioParams, 'CenterLatitude')
                mapRadiusKm = scenarioParams.MapRadiusKm * 1.5; % थोड़ा और बड़ा दायरा दिखाएं
                deltaLat = mapRadiusKm / 111.0;
                deltaLon = mapRadiusKm / (111.0 * cosd(scenarioParams.CenterLatitude));
                latLim = [scenarioParams.CenterLatitude - deltaLat, scenarioParams.CenterLatitude + deltaLat];
                lonLim = [scenarioParams.CenterLongitude - deltaLon, scenarioParams.CenterLongitude + deltaLon];
                geolimits(ax, latLim, lonLim);
            elseif ~isempty(customers) || ~isempty(candidateDepots)
                allLats = []; allLons = [];
                if ~isempty(customers), allLats = [allLats, custLats]; allLons = [allLons, custLons]; end
                if ~isempty(candidateDepots), allLats = [allLats, candLats]; allLons = [allLons, candLons]; end
                if ~isempty(allLats)
                    geolimits(ax, [min(allLats)-0.01, max(allLats)+0.01], [min(allLons)-0.01, max(allLons)+0.01]);
                end
            end

        catch ME_map
            warning('plot_Candidate_Vs_Selected_Hubs:MapToolboxError', ...
                    'Mapping Toolbox error: %s. Plotting with basic scatter.', ME_map.message);
            plotBasicScatter(); % Fallback to basic plot
        end
    else
        disp('Mapping Toolbox not found. Using basic scatter plot for hub locations.');
        plotBasicScatter(); % Fallback to basic plot
    end
    
    function plotBasicScatter()
        clf(fig); % Clear figure for basic plot
        ax_basic = axes(fig);
         if ~isempty(customers)
            plot(ax_basic, [customers.Longitude], [customers.Latitude], '.b', 'MarkerSize', 10, 'DisplayName', 'Customers');
            hold(ax_basic, 'on');
        end
        if ~isempty(candidateDepots)
            plot(ax_basic, [candidateDepots.Longitude], [candidateDepots.Latitude], 'ok', 'MarkerSize', 6, ...
                 'MarkerFaceColor', [0.7 0.7 0.7], 'DisplayName', 'Candidate Depots');
             hold(ax_basic, 'on');
        end
        if ~isempty(selectedHubs)
            plot(ax_basic, [selectedHubs.Longitude], [selectedHubs.Latitude], '^r', 'MarkerSize', 10, ...
                 'MarkerFaceColor', 'r', 'LineWidth', 1.5, 'DisplayName', 'Selected Hubs');
        end
        hold(ax_basic, 'off');
        xlabel(ax_basic, 'Longitude'); ylabel(ax_basic, 'Latitude');
        title(ax_basic, [plotTitle, ' (Basic Plot)']);
        legend(ax_basic, 'show', 'Location', 'bestoutside');
        axis(ax_basic, 'equal'); grid(ax_basic, 'on');
    end

    fprintf('Plot generated: %s\n', plotTitle);
end