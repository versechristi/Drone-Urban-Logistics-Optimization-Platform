% File: Drone_Urban_Logistics_Platform/+path_planning_algorithms/+ant_colony_vrp/calculate_Total_Cost_ACO.m
function totalCost = calculate_Total_Cost_ACO(solution, locations, demands, droneParams, numSelectedHubs, ~) % utils argument marked as unused
% Calculates the total cost of a given solution (set of routes) for ACO.
% Includes penalties for constraint violations (payload, range, unserved customers).
%
% INPUTS:
%   solution (cell array): Set of routes. Each route is a vector of location indices.
%   locations (Nx2 matrix): Coordinates. First numSelectedHubs are hubs.
%   demands (Mx1 vector): Demands for customers (M = number of customers).
%   droneParams (struct): Drone specs (.PayloadCapacity, .MaxRangeKm, .UnitCostPerKm).
%   numSelectedHubs (integer): Number of active hubs.
%   ~ (any, optional): Formerly utils struct, now unused.
%
% OUTPUTS:
%   totalCost (double): Total cost of the solution.

    totalCost = 0;
    hugePenalty = 1e7; % Penalty for infeasible solutions

    if isempty(solution)
        if ~isempty(demands) && sum(demands) > 0 % If there are demands but no solution
            totalCost = hugePenalty * length(demands); % Penalize for unserved customers
        end
        return;
    end
    
    numCustomers = length(demands);

    for r = 1:length(solution)
        route = solution{r};

        if isempty(route) || length(route) <= 2 % Skip empty or depot-depot only routes
            continue;
        end

        routeActualCost = 0;
        routeDistance = 0;
        routeDemand = 0;
        
        startNodeIdx = route(1);
        endNodeIdx = route(end);

        if startNodeIdx < 1 || startNodeIdx > numSelectedHubs || ...
           endNodeIdx < 1 || endNodeIdx > numSelectedHubs || ...
           startNodeIdx ~= endNodeIdx
            totalCost = totalCost + hugePenalty * 10; 
            continue; 
        end

        validRouteSegment = true;
        for i = 1:(length(route) - 1)
            loc1Idx = route(i);
            loc2Idx = route(i+1);

            if loc1Idx < 1 || loc1Idx > size(locations,1) || loc2Idx < 1 || loc2Idx > size(locations,1)
                totalCost = totalCost + hugePenalty * 20;
                validRouteSegment = false;
                break;
            end

            lat1 = locations(loc1Idx, 1);
            lon1 = locations(loc1Idx, 2);
            lat2 = locations(loc2Idx, 1);
            lon2 = locations(loc2Idx, 2);

            % --- MODIFICATION: Call Haversine distance directly from common_utilities ---
            segmentDistance = common_utilities.calculate_Haversine_Distance(lat1, lon1, lat2, lon2); %
            segmentCost = segmentDistance * droneParams.UnitCostPerKm;
            
            routeDistance = routeDistance + segmentDistance;
            routeActualCost = routeActualCost + segmentCost;

            if loc2Idx > numSelectedHubs
                 customerIndexInDemandsArray = loc2Idx - numSelectedHubs;
                 if customerIndexInDemandsArray < 1 || customerIndexInDemandsArray > numCustomers
                     totalCost = totalCost + hugePenalty * 25;
                     validRouteSegment = false;
                     break;
                 end
                 routeDemand = routeDemand + demands(customerIndexInDemandsArray);
            end
        end

        if ~validRouteSegment
            continue;
        end
        
        violationPenalty = 0;
        if routeDemand > droneParams.PayloadCapacity
            violationPenalty = violationPenalty + hugePenalty * ((routeDemand / droneParams.PayloadCapacity) - 1)^2;
        end
        if routeDistance > droneParams.MaxRangeKm
            violationPenalty = violationPenalty + hugePenalty * ((routeDistance / droneParams.MaxRangeKm) - 1)^2;
        end

        if violationPenalty > 0
            totalCost = totalCost + routeActualCost + violationPenalty; 
        else
            totalCost = totalCost + routeActualCost;
        end
    end
    
    allRoutedCustomerIndices = [];
    for r = 1:length(solution)
        route = solution{r};
        if isempty(route) || length(route) <= 2, continue; end
        customerNodesInRoute = route( (route > numSelectedHubs) );
        allRoutedCustomerIndices = [allRoutedCustomerIndices, customerNodesInRoute];
    end
    allRoutedCustomerIndices = unique(allRoutedCustomerIndices);
    
    numServedCustomers = length(allRoutedCustomerIndices);
    if numServedCustomers < numCustomers
        unservedPenalty = hugePenalty * (numCustomers - numServedCustomers) * 5;
        totalCost = totalCost + unservedPenalty;
    end
    
    if isnan(totalCost)
        totalCost = inf;
    end
end