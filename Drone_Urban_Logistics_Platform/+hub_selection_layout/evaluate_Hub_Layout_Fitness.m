% File: Drone_Urban_Logistics_Platform/+hub_selection_layout/evaluate_Hub_Layout_Fitness.m
function layoutMetrics = evaluate_Hub_Layout_Fitness(selectedHubs, customers, ~) % utils argument marked as unused
% Evaluates the fitness of a selected hub layout.
% Calculates average and maximum distance from customers to their nearest selected hub.
%
% INPUTS:
%   selectedHubs (struct array): The selected hub locations (needs .Latitude, .Longitude).
%   customers (struct array): Customer data (needs .Latitude, .Longitude).
%   ~ (any, optional): Formerly utils struct, now unused.
%
% OUTPUTS:
%   layoutMetrics (struct): A struct containing evaluation metrics:
%       .AvgDistToNearestHub (double)
%       .MaxDistToNearestHub (double)
%       .CustomerAssignments (array): For each customer, the ID of the nearest hub.

    fprintf('Evaluating hub layout fitness...\n');
    
    if isempty(selectedHubs)
        layoutMetrics.AvgDistToNearestHub = inf;
        layoutMetrics.MaxDistToNearestHub = inf;
        layoutMetrics.CustomerToHubDistances = [];
        layoutMetrics.CustomerAssignmentsToHubID = [];
        fprintf('No selected hubs to evaluate.\n');
        return;
    end
    if isempty(customers)
        layoutMetrics.AvgDistToNearestHub = 0;
        layoutMetrics.MaxDistToNearestHub = 0;
        layoutMetrics.CustomerToHubDistances = [];
        layoutMetrics.CustomerAssignmentsToHubID = [];
        fprintf('No customers to evaluate.\n');
        return;
    end

    numCustomers = length(customers);
    customerToHubDistances = zeros(numCustomers, 1);
    customerAssignmentsToHubID = zeros(numCustomers, 1);

    selectedHubCoords = [vertcat(selectedHubs.Latitude), vertcat(selectedHubs.Longitude)];
    selectedHubIDs = [vertcat(selectedHubs.ID)]';

    for i = 1:numCustomers
        custLat = customers(i).Latitude;
        custLon = customers(i).Longitude;
        
        minDistToHub = inf;
        assignedHubID = -1;
        
        for j = 1:length(selectedHubs)
            hubLat = selectedHubCoords(j, 1);
            hubLon = selectedHubCoords(j, 2);
            
            % --- MODIFICATION: Call Haversine distance directly from common_utilities ---
            dist = common_utilities.calculate_Haversine_Distance(custLat, custLon, hubLat, hubLon); %
            
            if dist < minDistToHub
                minDistToHub = dist;
                assignedHubID = selectedHubIDs(j);
            end
        end
        customerToHubDistances(i) = minDistToHub;
        customerAssignmentsToHubID(i) = assignedHubID;
    end
    
    layoutMetrics.AvgDistToNearestHub = mean(customerToHubDistances);
    layoutMetrics.MaxDistToNearestHub = max(customerToHubDistances);
    layoutMetrics.CustomerToHubDistances = customerToHubDistances;
    layoutMetrics.CustomerAssignmentsToHubID = customerAssignmentsToHubID;

    fprintf('Layout evaluation complete: AvgDist=%.2f km, MaxDist=%.2f km.\n', ...
            layoutMetrics.AvgDistToNearestHub, layoutMetrics.MaxDistToNearestHub);
end