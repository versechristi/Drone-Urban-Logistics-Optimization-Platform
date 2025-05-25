% File: Drone_Urban_Logistics_Platform/+hub_selection_layout/+visualizer/plot_Hub_Service_Areas.m
function fig = plot_Hub_Service_Areas(selectedHubs, customers, customerAssignmentsToHubID, scenarioParams, plotTitle)
% Plots selected hubs and customer assignments (lines from customer to assigned hub).
%
% INPUTS:
%   selectedHubs (struct array): Selected hubs (.ID, .Latitude, .Longitude).
%   customers (struct array): Customer data (.Latitude, .Longitude).
%   customerAssignmentsToHubID (array): For each customer, the ID of their assigned hub.
%   scenarioParams (struct, optional): For map center/radius.
%   plotTitle (string, optional): Title for the plot.

    if nargin < 5 || isempty(plotTitle)
        plotTitle = 'Hub Service Areas (Nearest Hub Assignment)';
    end
    if nargin < 4
        scenarioParams = [];
    end

    fig = []; % Initialize fig as empty
    try
        fig = figure('Name', plotTitle, 'Visible', 'off', 'HandleVisibility', 'callback');
    catch ME_fig_create
        warning('plot_Hub_Service_Areas:FigureCreationError', 'Failed to create figure: %s. Returning empty.', ME_fig_create.message);
        fig = []; % Ensure fig is empty if creation fails
        return; % Exit function
    end

    try
        % Check for empty input data
        if isempty(selectedHubs) || isempty(customers) || isempty(customerAssignmentsToHubID)
            if ishandle(fig) % fig should be valid if figure() succeeded
                ax_text = axes(fig);
                text(0.5, 0.5, 'Not enough data to plot service areas.', 'HorizontalAlignment', 'center', 'Parent', ax_text);
                title(ax_text, plotTitle); % Main title
                drawnow; 
                fprintf('Plot generated (empty data - text only): %s\n', plotTitle);
            else
                warning('plot_Hub_Service_Areas:InvalidFigHandleEarly', 'Figure handle was invalid even for empty data plot text.');
                if ~isempty(fig), fig = []; end 
            end
            finalize_figure_and_return(); % Call finalization logic
            return; % Return from function
        end
        
        hubMap = containers.Map('KeyType', 'double', 'ValueType', 'any');
        for i = 1:length(selectedHubs)
            hubMap(selectedHubs(i).ID) = selectedHubs(i);
        end

        useGeoPlot = license('test', 'MAP_Toolbox') && ~isempty(selectedHubs) && isfield(selectedHubs(1), 'Latitude');
        
        if useGeoPlot
            try
                ax = geoaxes(fig); 
                geobasemap(ax, 'streets-light');
                hold(ax, 'on');
                
                hubPlotHandles = gobjects(length(selectedHubs), 1); 
                if ~isempty(selectedHubs)
                    hubColors = lines(length(selectedHubs)); 
                    for i = 1:length(selectedHubs)
                         hubPlotHandles(i) = geoplot(ax, selectedHubs(i).Latitude, selectedHubs(i).Longitude, ...
                                '^', 'MarkerSize', 12, 'MarkerFaceColor', hubColors(i,:), ...
                                'MarkerEdgeColor', 'k', 'DisplayName', ['Hub ', num2str(selectedHubs(i).ID)]);
                    end
                end

                for i = 1:length(customers)
                    custLat = customers(i).Latitude;
                    custLon = customers(i).Longitude;
                    assignedHubID = customerAssignmentsToHubID(i);
                    
                    if isKey(hubMap, assignedHubID)
                        assignedHub = hubMap(assignedHubID);
                        hubLat = assignedHub.Latitude;
                        hubLon = assignedHub.Longitude;
                        
                        hubIdxForColor = find([selectedHubs.ID] == assignedHubID, 1);
                        if ~isempty(hubIdxForColor) 
                            lineColor = hubColors(hubIdxForColor(1), :); 
                            
                            geoplot(ax, custLat, custLon, 'o', 'MarkerSize', 6, ...
                                    'MarkerFaceColor', lineColor, 'MarkerEdgeColor', lineColor*0.8); 
                            geoplot(ax, [custLat, hubLat], [custLon, hubLon], '-', 'Color', [lineColor, 0.6]); 
                        end
                    end
                end
                
                hold(ax, 'off');
                title(ax, plotTitle, 'Interpreter', 'none'); % Main title
                
                validLegendHandles = hubPlotHandles(isgraphics(hubPlotHandles) & arrayfun(@isvalid, hubPlotHandles(isgraphics(hubPlotHandles))));
                if ~isempty(validLegendHandles)
                    legend(validLegendHandles, 'Location', 'bestoutside'); 
                end
                
                if ~isempty(scenarioParams) && isfield(scenarioParams, 'CenterLatitude') && isfield(scenarioParams, 'MapRadiusKm')
                    mapRadiusKm = scenarioParams.MapRadiusKm * 1.5;
                    deltaLat = mapRadiusKm / 111.0;
                    deltaLon = mapRadiusKm / (111.0 * cosd(scenarioParams.CenterLatitude));
                    latLim = [scenarioParams.CenterLatitude - deltaLat, scenarioParams.CenterLatitude + deltaLat];
                    lonLim = [scenarioParams.CenterLongitude - deltaLon, scenarioParams.CenterLongitude + deltaLon];
                    geolimits(ax, latLim, lonLim);
                end
                drawnow expose; 

            catch ME_map
                 warning('plot_Hub_Service_Areas:MapToolboxError', ...
                        'Mapping Toolbox error: %s. Plotting with basic scatter.', ME_map.message);
                plotBasicAssignments(); 
            end
        else
            fprintf('plot_Hub_Service_Areas: Mapping Toolbox not found or no hub geo-data. Using basic scatter plot.\n');
            plotBasicAssignments(); 
        end

    catch ME_main_plot 
        warning('plot_Hub_Service_Areas:MainPlottingError', 'Error during main plotting block: %s', ME_main_plot.message);
        if ishandle(fig)
            try
                clf(fig); 
                ax_err = axes(fig);
                text(0.5,0.5, sprintf('Error plotting service areas:\n%s', ME_main_plot.message), ...
                    'HorizontalAlignment', 'center', 'Parent', ax_err, 'Interpreter', 'none');
                title(ax_err, plotTitle, 'Interpreter', 'none'); % Main title for error
                drawnow;
            catch ME_clf_text
                warning('plot_Hub_Service_Areas:ErrorInMainCatch', 'Further error during error display: %s', ME_clf_text.message);
                 if ~isempty(fig), fig = []; end
            end
        else
            if ~isempty(fig), fig = []; end
        end
    end

    finalize_figure_and_return();

    % --- Nested function plotBasicAssignments ---
    function plotBasicAssignments()
        if ~ishandle(fig)
            warning('plot_Hub_Service_Areas:plotBasicAssignments:InvalidFigHandle', 'Parent figure handle invalid. Attempting to create a new one for basic plot.');
            if isnumeric(fig) && ~isempty(fig) 
                try close(fig); catch; end 
            end
            fig = figure('Name', [plotTitle, ' (Basic Plot - New Fig)'], 'Visible', 'off', 'HandleVisibility', 'callback'); 
            if ~ishandle(fig)
                 warning('plot_Hub_Service_Areas:plotBasicAssignments:FailedToCreateNewFig', 'Failed to create new figure for basic plot. Plotting will be skipped.');
                fig = []; 
                return; 
            end
        end
        
        try
            clf(fig); 
            ax_basic = axes(fig); 
            hold(ax_basic, 'on');
            
            if isempty(selectedHubs)
                text(0.5,0.5, 'No selected hubs for basic plot.', 'HorizontalAlignment', 'center', 'Parent', ax_basic);
                title(ax_basic, [plotTitle, ' (Basic Plot - No Hubs)']); % Main title
                hold(ax_basic, 'off'); grid(ax_basic, 'on'); drawnow;
                return;
            end

            hubColors_basic = lines(length(selectedHubs)); 
            hubPlotHandles_basic = gobjects(length(selectedHubs), 1); 

            for k_hub = 1:length(selectedHubs) 
                hubPlotHandles_basic(k_hub) = plot(ax_basic, selectedHubs(k_hub).Longitude, selectedHubs(k_hub).Latitude, ...
                     '^', 'MarkerSize', 12, 'MarkerFaceColor', hubColors_basic(k_hub,:), ...
                     'MarkerEdgeColor', 'k', 'DisplayName', ['Hub ', num2str(selectedHubs(k_hub).ID)]);
            end
            
            if ~isempty(customers) && ~isempty(customerAssignmentsToHubID)
                for k_cust = 1:length(customers) 
                    custLon = customers(k_cust).Longitude;
                    custLat = customers(k_cust).Latitude;
                    assignedHubID_basic = customerAssignmentsToHubID(k_cust); 
                    
                    if isKey(hubMap, assignedHubID_basic)
                        assignedHub_basic = hubMap(assignedHubID_basic); 
                        hubLon_basic = assignedHub_basic.Longitude; 
                        hubLat_basic = assignedHub_basic.Latitude; 
                        
                        hubIdxForColor_basic = find([selectedHubs.ID] == assignedHubID_basic, 1); 
                        if ~isempty(hubIdxForColor_basic)
                            lineColor_basic = hubColors_basic(hubIdxForColor_basic(1), :); 
                            
                            plot(ax_basic, custLon, custLat, 'o', 'MarkerSize', 6, ...
                                 'MarkerFaceColor', lineColor_basic, 'MarkerEdgeColor', lineColor_basic*0.8);
                            plot(ax_basic, [custLon, hubLon_basic], [custLat, hubLat_basic], '-', 'Color', [lineColor_basic, 0.6]);
                        end
                    end
                end
            else
                 text(0.25,0.25, 'No customer data/assignments for basic plot.', 'HorizontalAlignment', 'center', 'Parent', ax_basic, 'Color', 'r');
            end

            hold(ax_basic, 'off');
            xlabel(ax_basic, 'Longitude'); ylabel(ax_basic, 'Latitude');
            title(ax_basic, [plotTitle, ' (Basic Plot)'], 'Interpreter', 'none'); % Main title
            
            validLegendHandles_basic = hubPlotHandles_basic(isgraphics(hubPlotHandles_basic) & arrayfun(@isvalid, hubPlotHandles_basic(isgraphics(hubPlotHandles_basic))));
            if ~isempty(validLegendHandles_basic)
                legend(validLegendHandles_basic, 'Location', 'bestoutside');
            end
            axis(ax_basic, 'equal'); grid(ax_basic, 'on');
            drawnow; 
        catch ME_basic_plot
            warning('plot_Hub_Service_Areas:plotBasicAssignments:PlottingError', 'Error during basic plot drawing: %s', ME_basic_plot.message);
            if ishandle(fig)
                try clf(fig); catch; end 
                 ax_err_basic = axes(fig);
                 text(0.5,0.5, sprintf('Error in basic plot:\n%s', ME_basic_plot.message), 'HorizontalAlignment', 'center', 'Parent', ax_err_basic);
                 title(ax_err_basic, [plotTitle, ' (Basic Plot Error)']); % Main title for error
                 drawnow;
            else
                if ~isempty(fig), fig = []; end 
            end
        end
    end % End of plotBasicAssignments

    % --- Nested function finalize_figure_and_return ---
    function finalize_figure_and_return()
        % --- MODIFICATION: Corrected 'get' function call ---
        if ~isempty(fig) && (~ishandle(fig) || ~strcmp(get(fig, 'Type'), 'figure')) 
        % --- END MODIFICATION ---
            fprintf('INFO (plot_Hub_Service_Areas): Figure handle (value: %.16g) is invalid or not a figure type before final return. Setting to [].\n', double(fig));
            fig = []; 
        end

        if ishandle(fig) 
            % REMOVED SGTITLE:
            % try
            %     sgtitle(fig, ['Service Areas | ', plotTitle], 'Interpreter', 'none'); 
            % catch ME_sgtitle
            %     warning('plot_Hub_Service_Areas:SgtitleError', 'Could not set super title: %s. Figure handle might be problematic.', ME_sgtitle.message);
            %     if ~ishandle(fig)
            %         fprintf('INFO (plot_Hub_Service_Areas): Figure handle became invalid after sgtitle error. Setting to [].\n');
            %         fig = [];
            %     end
            % end
            
            if ishandle(fig) && ~nargout 
                if strcmp(get(fig, 'Visible'), 'off')
                     set(fig, 'Visible', 'on');
                end
            end
        end
        
        if ishandle(fig)
            fprintf('Plot function "%s" completed. Figure handle is valid before return.\n', mfilename);
        else
            fprintf('Plot function "%s" completed. Figure handle is NOT valid before return. Returning %s.\n', mfilename, mat2str(fig));
            if ~isempty(fig) 
                fig = []; 
            end
        end
    end % End of finalize_figure_and_return
end