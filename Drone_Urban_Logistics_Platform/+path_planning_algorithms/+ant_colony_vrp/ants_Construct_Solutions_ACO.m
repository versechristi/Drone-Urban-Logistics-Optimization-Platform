% File: Drone_Urban_Logistics_Platform/+path_planning_algorithms/+ant_colony_vrp/ants_Construct_Solutions_ACO.m
function [antTotalSolution, antTotalCost] = ants_Construct_Solutions_ACO(antID, pheromoneTrails, heuristicInfo, ...
    locations, demands, numSelectedHubs, droneParams, paramsACO) % MODIFIED: Removed utils argument (was '~')
% An ant constructs a complete solution (set of routes) for the MDVRP.
%
% OUTPUTS:
%   antTotalSolution (cell array): The set of routes constructed by this ant.
%   antTotalCost (double): The total cost of this ant's solution.

    numCustomers = length(demands);
    allCustomerGlobalIndices = (numSelectedHubs+1) : (numSelectedHubs+numCustomers);
    
    unvisitedCustomerGlobalIndices = allCustomerGlobalIndices;
    antTotalSolution = {}; 
    
    maxRoutesPerAnt = numCustomers; 
    routeCount = 0;

    while ~isempty(unvisitedCustomerGlobalIndices) && routeCount < maxRoutesPerAnt
        routeCount = routeCount + 1;
        currentRoute = [];
        currentRouteDemand = 0;
        currentRouteDistance = 0;
        
        if numSelectedHubs == 0
            % This case should ideally be handled before calling this function,
            % e.g., in solve_ACO_VRP or main_Orchestrator.
            warning('ants_Construct_Solutions_ACO:NoHubs', 'Ant %d: No hubs to start route from. Returning empty solution.', antID);
            antTotalSolution = {};
            antTotalCost = inf; % Penalize heavily
            return;
        end
        startDepotGlobalIdx = randi([1, numSelectedHubs]);
        
        currentLocationGlobalIdx = startDepotGlobalIdx;
        currentRoute = [currentRoute, currentLocationGlobalIdx];
        
        while true 
            possibleNextCustomers = []; 
            selectionProbabilities = [];
            
            for custIdx_potential_loop = 1:length(unvisitedCustomerGlobalIndices)
                nextCustomerGlobalIdx = unvisitedCustomerGlobalIndices(custIdx_potential_loop);
                
                % Demand for the specific customer (index needs to be relative to the 'demands' array)
                demand_idx_for_array = nextCustomerGlobalIdx - numSelectedHubs;
                if demand_idx_for_array < 1 || demand_idx_for_array > length(demands)
                    warning('ants_Construct_Solutions_ACO:InvalidDemandIndex', 'Ant %d: Invalid index for demands array for customer global index %d.', antID, nextCustomerGlobalIdx);
                    continue; 
                end
                customerDemand = demands(demand_idx_for_array);
                
                if currentRouteDemand + customerDemand <= droneParams.PayloadCapacity
                    % MODIFICATION START: Direct call to common_utilities
                    distToNextCust = common_utilities.calculate_Haversine_Distance(...
                        locations(currentLocationGlobalIdx,1), locations(currentLocationGlobalIdx,2), ...
                        locations(nextCustomerGlobalIdx,1), locations(nextCustomerGlobalIdx,2));
                    
                    distNextCustToDepot = common_utilities.calculate_Haversine_Distance(...
                        locations(nextCustomerGlobalIdx,1), locations(nextCustomerGlobalIdx,2), ...
                        locations(startDepotGlobalIdx,1), locations(startDepotGlobalIdx,2));
                    % MODIFICATION END
                    
                    if currentRouteDistance + distToNextCust + distNextCustToDepot <= droneParams.MaxRangeKm
                        possibleNextCustomers = [possibleNextCustomers, nextCustomerGlobalIdx];
                        
                        tau_ij = max(pheromoneTrails(currentLocationGlobalIdx, nextCustomerGlobalIdx), 1e-9); 
                        eta_ij = heuristicInfo(currentLocationGlobalIdx, nextCustomerGlobalIdx);
                        prob = (tau_ij ^ paramsACO.Alpha_PheromoneImportance) * ...
                               (eta_ij ^ paramsACO.Beta_HeuristicImportance);
                        selectionProbabilities = [selectionProbabilities, prob];
                    end
                end
            end
            
            if isempty(possibleNextCustomers)
                break; 
            else
                if sum(selectionProbabilities) < 1e-9 % Check for near-zero sum to avoid NaN from division by zero
                    chosenIdxInPossible = randi(length(possibleNextCustomers)); % Fallback to random choice
                else
                    selectionProbabilities = selectionProbabilities / sum(selectionProbabilities);
                    % Ensure probabilities are not NaN due to 0/0 from prob calculation if all tau/eta are 0
                    if any(isnan(selectionProbabilities)) 
                        selectionProbabilities(isnan(selectionProbabilities)) = 1/length(possibleNextCustomers); % Equal probability if NaN
                        selectionProbabilities = selectionProbabilities / sum(selectionProbabilities); % Re-normalize
                    end
                    chosenIdxInPossible = find(rand <= cumsum(selectionProbabilities), 1, 'first');
                    if isempty(chosenIdxInPossible) % Safety net if cumsum logic fails (e.g. all probs zero and fallback missed)
                        chosenIdxInPossible = randi(length(possibleNextCustomers));
                    end
                end
                
                selectedNextCustomerGlobalIdx = possibleNextCustomers(chosenIdxInPossible);
                
                % MODIFICATION START: Direct call to common_utilities
                distToSelected = common_utilities.calculate_Haversine_Distance(...
                    locations(currentLocationGlobalIdx,1), locations(currentLocationGlobalIdx,2), ...
                    locations(selectedNextCustomerGlobalIdx,1), locations(selectedNextCustomerGlobalIdx,2));
                % MODIFICATION END
                
                currentRouteDistance = currentRouteDistance + distToSelected;
                currentRouteDemand = currentRouteDemand + demands(selectedNextCustomerGlobalIdx - numSelectedHubs);
                currentRoute = [currentRoute, selectedNextCustomerGlobalIdx];
                currentLocationGlobalIdx = selectedNextCustomerGlobalIdx;
                
                unvisitedCustomerGlobalIndices(unvisitedCustomerGlobalIndices == selectedNextCustomerGlobalIdx) = [];
            end
        end 
        
        if length(currentRoute) > 1 
            currentRoute = [currentRoute, startDepotGlobalIdx];
            antTotalSolution{end+1} = currentRoute;
        end
    end 

    if ~isempty(unvisitedCustomerGlobalIndices)
         % fprintf('Ant %d could not visit all customers. %d remaining.\n', antID, length(unvisitedCustomerGlobalIndices));
    end

    % Calculate total cost using the dedicated cost function from the same package
    % The calculate_Total_Cost_ACO function should also be updated to not expect 'utils'
    antTotalCost = path_planning_algorithms.ant_colony_vrp.calculate_Total_Cost_ACO(...
                    antTotalSolution, locations, demands, droneParams, numSelectedHubs); % MODIFIED: Removed utils (struct())
end