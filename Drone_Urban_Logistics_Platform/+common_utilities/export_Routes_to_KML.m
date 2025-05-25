% File: Drone_Urban_Logistics_Platform/+common_utilities/export_Routes_to_KML.m
function export_Routes_to_KML(solution, locations, demands, numSelectedHubs, customerStruct, hubStruct, kmlFilePath, fileDescriptionPrefix)
% Exports the VRP solution (routes, hubs, customers) to a KML file.
%
% INPUTS:
%   solution (cell array): The VRP solution (set of routes).
%                           Each route is [hubIdx, cust1GlobalIdx, ..., hubIdx].
%   locations (Nx2 matrix): Coordinates [Lat, Lon]. First numSelectedHubs are hubs.
%   demands (vector): Customer demands (for customer descriptions).
%   numSelectedHubs (integer): Number of active hubs.
%   customerStruct (struct array): Original customer data with IDs (for naming).
%   hubStruct (struct array): Original selected hub data with IDs (for naming).
%   kmlFilePath (string): Full path for the output KML file.
%   fileDescriptionPrefix (string, optional): Prefix for KML document name/description (e.g., "SA Final", "ACO Iter 50").

    fprintf('Exporting solution to KML file: %s\n', kmlFilePath);
    
    if nargin < 8 || isempty(fileDescriptionPrefix)
        fileDescriptionPrefix = 'VRP Solution';
    end

    if ~license('test', 'Mapping Toolbox')
        warning('export_Routes_to_KML:NoMapToolbox', 'Mapping Toolbox not found. KML export skipped.');
        return;
    end

    try
        % --- Prepare Placemarks for Hubs and Customers ---
        numCustomers = 0;
        if ~isempty(demands)
            numCustomers = length(demands);
        end
        
        placemarkShapes = geopointshape.empty(0,1);
        placemarkNames = cell(0,1);
        placemarkDescriptions = cell(0,1);
        placemarkIcons = cell(0,1);
        placemarkIconScales = ones(0,1); % Ensure numeric, default to 1.0

        % Hub Placemarks
        hubIconUrl = 'http://maps.google.com/mapfiles/kml/paddle/H.png'; % Standard KML hub icon
        if numSelectedHubs > 0 && ~isempty(hubStruct)
            for i = 1:numSelectedHubs
                % Assuming hubStruct contains the selected hubs and its order corresponds
                % to the first numSelectedHubs entries in the 'locations' array.
                if i <= length(hubStruct) && i <= size(locations,1)
                    currentHubData = hubStruct(i); % Get original ID from hubStruct
                    hubLatInLoc = locations(i,1);
                    hubLonInLoc = locations(i,2);
                    
                    % Verify that the hub from hubStruct matches the coordinates in locations(i,:)
                    % This is a sanity check; ideally, they should always match if data is consistent.
                    if isfield(currentHubData, 'Latitude') && isfield(currentHubData, 'Longitude') && ...
                       abs(currentHubData.Latitude - hubLatInLoc) > 1e-5 && ...
                       abs(currentHubData.Longitude - hubLonInLoc) > 1e-5
                        warning('export_Routes_to_KML:HubCoordinateMismatch', ...
                                'Hub %d (ID: %d) from hubStruct has different coordinates than locations(%d,:). Using locations data.', ...
                                i, currentHubData.ID, i);
                    end

                    placemarkShapes(end+1,1) = geopointshape(hubLatInLoc, hubLonInLoc);
                    placemarkNames{end+1,1} = sprintf('Hub %d (ID: %d)', i, currentHubData.ID);
                    placemarkDescriptions{end+1,1} = sprintf('Selected Hub %d (Original ID: %d)\nLat: %.5f, Lon: %.5f', ...
                                                         i, currentHubData.ID, hubLatInLoc, hubLonInLoc);
                    placemarkIcons{end+1,1} = hubIconUrl;
                    placemarkIconScales(end+1,1) = 1.2; % Make hubs slightly larger
                else
                     warning('export_Routes_to_KML:HubDataInconsistency', ...
                             'Cannot create placemark for hub index %d. Check consistency between numSelectedHubs, length(hubStruct), and size(locations,1).', i);
                end
            end
        end

        % Customer Placemarks
        customerIconUrl = 'http://maps.google.com/mapfiles/kml/paddle/C.png'; % Standard KML customer icon
        if numCustomers > 0 && ~isempty(customerStruct)
            for i = 1:numCustomers
                customerGlobalIdxInLocations = numSelectedHubs + i; % Index in the combined 'locations' array
                % Ensure all indices are valid before accessing arrays
                if customerGlobalIdxInLocations <= size(locations,1) && ...
                   i <= length(customerStruct) && ...
                   i <= length(demands)
                    
                    placemarkShapes(end+1,1) = geopointshape(locations(customerGlobalIdxInLocations,1), locations(customerGlobalIdxInLocations,2));
                    placemarkNames{end+1,1} = sprintf('Customer %d (ID: %d)', i, customerStruct(i).ID);
                    placemarkDescriptions{end+1,1} = sprintf('Customer %d (Original ID: %d)\nDemand: %d\nLat: %.5f, Lon: %.5f', ...
                                                         i, customerStruct(i).ID, demands(i), ...
                                                         locations(customerGlobalIdxInLocations,1), locations(customerGlobalIdxInLocations,2));
                    placemarkIcons{end+1,1} = customerIconUrl;
                    placemarkIconScales(end+1,1) = 1.0; % Default scale
                else
                    warning('export_Routes_to_KML:CustomerDataInconsistency', ...
                            'Cannot create placemark for customer index %d (GlobalLocIdx: %d). Check array bounds for locations, customerStruct, and demands.', ...
                            i, customerGlobalIdxInLocations);
                end
            end
        end
        
        T_placemarks = table(placemarkShapes, placemarkNames, placemarkDescriptions, placemarkIcons, placemarkIconScales, ...
            'VariableNames', {'Shape', 'Name', 'Description', 'Icon', 'IconScale'});

        % --- Prepare LineStrings for Routes ---
        routeShapes = geolineshape.empty(0,1);
        routeNames = cell(0,1);
        routeDescriptions = cell(0,1);
        routeColorsKML = cell(0,1); 
        
        validRouteCounter = 0;
        if ~isempty(solution)
            validRoutesIndices = find(cellfun(@(r) ~isempty(r) && length(r) > 2, solution));
            numValidRoutesToPlot = length(validRoutesIndices);
            
            if numValidRoutesToPlot > 0
                matlabRouteColors = lines(numValidRoutesToPlot); % Generate distinct colors
                tempRouteColorsKML = common_utilities.convert_Matlab_to_KML_Colors(matlabRouteColors, 0.75); % Slightly transparent routes
                if numValidRoutesToPlot == 1 && ischar(tempRouteColorsKML) % Handle single color case
                    routeColorsKML = {tempRouteColorsKML}; 
                else
                    routeColorsKML = tempRouteColorsKML;
                end

                for r_idx_loop = 1:numValidRoutesToPlot % Loop through valid routes
                    route_solution_index = validRoutesIndices(r_idx_loop);
                    route = solution{route_solution_index};
                    % This route is already validated by cellfun, but as a safeguard:
                    if isempty(route) || length(route) <= 2, continue; end 
                    
                    validRouteCounter = validRouteCounter + 1;
                    % Ensure all indices in route are valid for 'locations'
                    if any(route < 1) || any(route > size(locations,1))
                        warning('export_Routes_to_KML:InvalidRouteIndex', 'Route %d contains invalid location indices. Skipping this route for KML.', validRouteCounter);
                        continue;
                    end
                    routeCoords = locations(route, :); 
                    
                    routeShapes(end+1,1) = geolineshape(routeCoords(:,1), routeCoords(:,2));
                    
                    % Determine original Hub ID for route name more robustly
                    hubOriginalIDforName = -1; % Default
                    if route(1) <= numSelectedHubs && route(1) <= length(hubStruct)
                        hubOriginalIDforName = hubStruct(route(1)).ID;
                    end
                    routeNames{end+1,1} = sprintf('Route %d (HubLocIdx %d, OrigID %d)', validRouteCounter, route(1), hubOriginalIDforName);
                    
                    descStr = sprintf('Optimized Route %d\nFrom Hub (Location Index %d, Original ID %d):\n', validRouteCounter, route(1), hubOriginalIDforName);
                    totalRouteDist = 0;
                    totalRouteDemand = 0;
                    
                    for leg = 1:(length(route)-1)
                        p1_loc_idx = route(leg); 
                        p2_loc_idx = route(leg+1);
                        
                        distLeg = common_utilities.calculate_Haversine_Distance(locations(p1_loc_idx,1),locations(p1_loc_idx,2),locations(p2_loc_idx,1),locations(p2_loc_idx,2)); %
                        totalRouteDist = totalRouteDist + distLeg;
                        
                        if p2_loc_idx > numSelectedHubs % If p2 is a customer
                            customer_idx_in_demands_array = p2_loc_idx - numSelectedHubs;
                            if customer_idx_in_demands_array > 0 && customer_idx_in_demands_array <= length(demands)
                                totalRouteDemand = totalRouteDemand + demands(customer_idx_in_demands_array);
                            end
                        end
                        
                        % Node naming using if/else for MATLAB compatibility
                        nodeNameP1 = '';
                        if p1_loc_idx <= numSelectedHubs
                            origHubID_p1 = -1;
                            if p1_loc_idx <= length(hubStruct), origHubID_p1 = hubStruct(p1_loc_idx).ID; end
                            nodeNameP1 = sprintf('Hub (Loc%d,ID%d)', p1_loc_idx, origHubID_p1);
                        else
                            origCustID_p1 = -1;
                            idx_in_cust_struct = p1_loc_idx - numSelectedHubs;
                            if idx_in_cust_struct > 0 && idx_in_cust_struct <= length(customerStruct)
                                origCustID_p1 = customerStruct(idx_in_cust_struct).ID;
                            end
                            nodeNameP1 = sprintf('Cust (Loc%d,ID%d)', p1_loc_idx, origCustID_p1);
                        end
                        
                        nodeNameP2 = '';
                        if p2_loc_idx <= numSelectedHubs
                            origHubID_p2 = -1;
                            if p2_loc_idx <= length(hubStruct), origHubID_p2 = hubStruct(p2_loc_idx).ID; end
                            nodeNameP2 = sprintf('Hub (Loc%d,ID%d)', p2_loc_idx, origHubID_p2);
                        else
                            origCustID_p2 = -1;
                            idx_in_cust_struct = p2_loc_idx - numSelectedHubs;
                            if idx_in_cust_struct > 0 && idx_in_cust_struct <= length(customerStruct)
                                origCustID_p2 = customerStruct(idx_in_cust_struct).ID;
                            end
                            nodeNameP2 = sprintf('Cust (Loc%d,ID%d)', p2_loc_idx, origCustID_p2);
                        end
                        
                        descStr = [descStr, sprintf('  %s -> %s (%.2f km)\n', nodeNameP1, nodeNameP2, distLeg)];
                    end
                    descStr = [descStr, sprintf('Total Route Demand: %d units\nTotal Route Distance: %.2f km', totalRouteDemand, totalRouteDist)];
                    routeDescriptions{end+1,1} = descStr;
                end
            end
        end
        
        % --- Write to KML File ---
        routesActuallyWritten = false;
        if ~isempty(routeShapes) % Check if any valid routes were processed to create shapes
            T_routes = table(routeShapes, routeNames, routeDescriptions, 'VariableNames', {'Shape', 'Name', 'Description'});
            [name_val_r, desc_val_r, ~, ~, color_val_r] = prepare_kml_params(T_routes, routeColorsKML);

            docNameForKML = [fileDescriptionPrefix, ' - Drone Routes'];
            if size(T_placemarks,1) > 0 % If placemarks will also be added
                 docNameForKML = [fileDescriptionPrefix, ' - Routes & Locations'];
            end

            kmlwrite(kmlFilePath, T_routes, ...
                     'Name', name_val_r, ...
                     'Description', desc_val_r, ...
                     'Color', color_val_r, ...
                     'LineWidth', 2.5, ...
                     'FeatureType', 'linestring', ...
                     'DocumentName', docNameForKML, ...
                     'DocumentDescription', ['Drone delivery routes and locations generated by optimization on ', datestr(now)]);
            routesActuallyWritten = true;
            fprintf('KML export: Routes written to %s.\n', kmlFilePath);
        end

        if size(T_placemarks,1) > 0 % Check if there are any placemarks to write (table has rows)
            [name_val_p, desc_val_p, icon_val_p, iconscale_val_p, ~] = prepare_kml_params(T_placemarks);
            if routesActuallyWritten % Append placemarks if routes were already written
                kmlwrite(kmlFilePath, T_placemarks, ...
                         'Name', name_val_p, ...
                         'Description', desc_val_p, ...
                         'Icon', icon_val_p, ...
                         'IconScale', iconscale_val_p, ...
                         'FeatureType', 'point', ...
                         'Append', true);
                fprintf('KML export: Placemarks appended to %s.\n', kmlFilePath);
            else % No routes written, so write placemarks as a new document
                kmlwrite(kmlFilePath, T_placemarks, ...
                         'Name', name_val_p, ...
                         'Description', desc_val_p, ...
                         'Icon', icon_val_p, ...
                         'IconScale', iconscale_val_p, ...
                         'FeatureType', 'point', ...
                         'DocumentName', [fileDescriptionPrefix, ' - Locations Only'], ...
                         'DocumentDescription', ['Hub and Customer locations on ', datestr(now)]);
                fprintf('KML export: Placemarks written (no routes) to %s.\n', kmlFilePath);
            end
        elseif ~routesActuallyWritten % Both routes and placemarks are empty
            % Create a minimal KML file indicating no features
            docNode = com.mathworks.xml.XMLUtils.createDocument('kml'); % Requires Java enabled
            docRootNode = docNode.getDocumentElement();
            docRootNode.setAttribute('xmlns','http://www.opengis.net/kml/2.2');
            docElement = docNode.createElement('Document');
            docRootNode.appendChild(docElement);
            nameElement = docNode.createElement('name');
            nameElement.setTextContent([fileDescriptionPrefix, ' - No Features']);
            docElement.appendChild(nameElement);
            descElement = docNode.createElement('description');
            descElement.setTextContent(['No routes or placemarks to display. Generated on ', datestr(now)]);
            docElement.appendChild(descElement);
            xmlwrite(kmlFilePath,docNode); % This writes the XML structure to the file
            fprintf('KML export: Empty KML (no features) written to %s.\n', kmlFilePath);
        end
        
        fprintf('KML export process completed for %s.\n', kmlFilePath);

    catch ME_kml
        warning('export_Routes_to_KML:KMLError', 'Error writing KML file "%s": %s', kmlFilePath, ME_kml.message);
        fprintf('Stack trace for KML error:\n');
        disp(ME_kml.getReport('extended', 'hyperlinks', 'off'));
    end
end

% Local helper function to prepare kmlwrite parameters
function [name_val, desc_val, icon_val, iconscale_val, color_val] = prepare_kml_params(T_data, colors)
% Helper to unwrap single-element cell parameters for kmlwrite.
% T_data is the table (e.g., T_routes or T_placemarks).
% colors is optional, only for routes.

    name_val = T_data.Name;
    desc_val = T_data.Description;
    
    icon_val = []; 
    iconscale_val = []; 
    color_val = []; 

    if ismember('Icon', T_data.Properties.VariableNames)
        icon_val = T_data.Icon;
    end
    if ismember('IconScale', T_data.Properties.VariableNames)
        iconscale_val = T_data.IconScale; % This will be a numeric column or [] if table is empty
    end
    if nargin > 1 && ~isempty(colors) 
        color_val = colors; % This will be a cell array of KML color strings or a single string
    end

    % If the table contains exactly one row, kmlwrite expects scalar values for these properties
    % if they were passed as cell arrays with one element or vectors with one element.
    if size(T_data, 1) == 1 
        if iscell(name_val) && numel(name_val) == 1
            name_val = name_val{1};
        end
        if iscell(desc_val) && numel(desc_val) == 1
            desc_val = desc_val{1};
        end
        if ~isempty(icon_val) && iscell(icon_val) && numel(icon_val) == 1
            icon_val = icon_val{1};
        end
        % iconscale_val from a table column is already numeric. If T_data has 1 row, 
        % T_data.IconScale is a scalar double. So, no change needed for iscell check.
        % kmlwrite handles scalar numeric IconScale correctly.
        
        if ~isempty(color_val) && iscell(color_val) && numel(color_val) == 1
            color_val = color_val{1};
        end
    end
end