% File: Drone_Urban_Logistics_Platform/+path_planning_algorithms/+simulated_annealing_vrp/generate_Neighbor_Solution_SA.m
function neighborSolution = generate_Neighbor_Solution_SA(currentSolution, numCustomers, numSelectedHubs, numLocations)
% Generates a neighboring solution by applying a random neighborhood operator.
% Based on the VRP neighborhood operators.
%
% INPUTS:
%   currentSolution (cell array): The current set of routes.
%   numCustomers (integer): Total number of customers.
%   numSelectedHubs (integer): Number of active hubs/depots.
%   numLocations (integer): Total number of locations (hubs + customers).
%
% OUTPUTS:
%   neighborSolution (cell array): The modified (neighbor) solution.

    neighborSolution = currentSolution;
    if isempty(neighborSolution) && numCustomers > 0
        % This case might indicate an issue upstream or a very poor state.
        % If it truly can be empty, one might call generate_Initial_Solution_SA here.
        % For simplicity, return current if no sensible operation can be performed.
        return;
    end
    if numCustomers == 0
        return; % No customers, no routes to modify
    end

    % Find indices of non-empty routes with at least one customer visit
    % A valid route looks like [depot, customer, ..., depot] so length > 2
    validRouteIndices = find(cellfun(@(c) ~isempty(c) && length(c) > 2, neighborSolution));

    if isempty(validRouteIndices)
        % If no valid routes with customers, try to create one if solution is just depot-depot pairs
        % or if all customers are somehow unassigned.
        allRoutedCustomers = [];
        for rIdx = 1:length(neighborSolution)
            route = neighborSolution{rIdx};
            if length(route) > 2 % Depot-Customer-...-Depot
                allRoutedCustomers = [allRoutedCustomers, route(2:end-1)];
            end
        end
        allRoutedCustomers = unique(allRoutedCustomers(allRoutedCustomers > numSelectedHubs)); % Global indices of customers

        allCustomerGlobalIndices = (numSelectedHubs+1):numLocations;
        unassignedCustomers = setdiff(allCustomerGlobalIndices, allRoutedCustomers);

        if ~isempty(unassignedCustomers)
            custToAssign = datasample(unassignedCustomers, 1);
            depotForNewRoute = randi([1, numSelectedHubs]);
            newRoute = [depotForNewRoute, custToAssign, depotForNewRoute];

            emptySlot = find(cellfun(@(c) isempty(c) || length(c) <=2, neighborSolution), 1);
            if ~isempty(emptySlot)
                neighborSolution{emptySlot} = newRoute;
            else
                neighborSolution{end+1} = newRoute;
            end
            % fprintf('SA_Neighbor: Added new route for unassigned customer %d.\n', custToAssign);
            return; % Return after this basic modification
        else
            % All customers routed but somehow no valid routes for operators.
            % This state implies routes are just [depot, depot] or empty.
            % fprintf('SA_Neighbor: No valid customer routes to operate on, and all customers seem routed or no customers.\n');
            return;
        end
    end

    % Determine operator type based on available routes
    numRoutesWithAtLeastOneCust = numRoutesWithMinCustomers(neighborSolution, validRouteIndices, 1);
    numRoutesWithAtLeastTwoCust = numRoutesWithMinCustomers(neighborSolution, validRouteIndices, 2);

    if numRoutesWithAtLeastOneCust >= 2 % For inter-route exchange or relocate
        operatorType = randi([1, 4]); % All operators possible
    elseif numRoutesWithAtLeastOneCust >= 1 % For intra-route 2-opt or relocate
        operatorType = randi([1, 2]);
    else
        % This case should have been caught by isempty(validRouteIndices) earlier
        % or the unassigned customer logic. If reached, something is unexpected.
        return;
    end

    operatorApplied = false;
    maxAttempts = 10;
    attempt = 0;

    while ~operatorApplied && attempt < maxAttempts
        attempt = attempt + 1;
        tempSolution = neighborSolution; % Work on a temporary copy for this attempt

        currentRouteIdxForDebug = []; % For error reporting

        try
            switch operatorType
                case 1 % 1. 2-opt (Intra-route swap of a segment)
                    % Requires at least one route with at least two customers
                    if numRoutesWithAtLeastTwoCust < 1
                        operatorType = selectFallBackOperatorType(operatorType, numRoutesWithAtLeastOneCust, numRoutesWithAtLeastTwoCust);
                        continue; % Try another operator if condition not met
                    end
                    % Select a route that has at least two customers
                    eligibleRouteIndices = validRouteIndices(arrayfun(@(idx) length(tempSolution{idx}) - 2 >= 2, validRouteIndices));
                    if isempty(eligibleRouteIndices) % Should not happen if numRoutesWithAtLeastTwoCust >= 1
                        operatorType = selectFallBackOperatorType(operatorType, numRoutesWithAtLeastOneCust, numRoutesWithAtLeastTwoCust);
                        continue;
                    end
                    routeIdx = datasample(eligibleRouteIndices, 1);
                    currentRouteIdxForDebug = routeIdx;
                    route = tempSolution{routeIdx};
                    
                    numCustInRoute = length(route) - 2;
                    % Indices refer to positions *within the customer part* of the route
                    idx_cust_part = sort(randperm(numCustInRoute, 2));
                    % Convert to indices in the full route array (offset by 1 for start depot)
                    i = idx_cust_part(1) + 1;
                    j = idx_cust_part(2) + 1;
                    
                    tempSolution{routeIdx} = [route(1:i-1), fliplr(route(i:j)), route(j+1:end)];
                    operatorApplied = true;

                case 2 % 2. Relocate (Intra-route move of a customer)
                    % Requires at least one route with at least one customer
                    if numRoutesWithAtLeastOneCust < 1
                        operatorType = selectFallBackOperatorType(operatorType, numRoutesWithAtLeastOneCust, numRoutesWithAtLeastTwoCust);
                        continue;
                    end
                    eligibleRouteIndices = validRouteIndices(arrayfun(@(idx) length(tempSolution{idx}) - 2 >= 1, validRouteIndices));
                     if isempty(eligibleRouteIndices)
                        operatorType = selectFallBackOperatorType(operatorType, numRoutesWithAtLeastOneCust, numRoutesWithAtLeastTwoCust);
                        continue;
                    end
                    routeIdx = datasample(eligibleRouteIndices, 1);
                    currentRouteIdxForDebug = routeIdx;
                    route = tempSolution{routeIdx};
                    numCustInRoute = length(route) - 2;

                    % Select a customer to move (its index in the route array)
                    custIdxInRouteArray = datasample(2:(numCustInRoute+1), 1);
                    customerNode = route(custIdxInRouteArray);

                    route_temp = route;
                    route_temp(custIdxInRouteArray) = []; % Remove customer

                    % Select a new insertion position (index in the *modified* route_temp)
                    % Can insert before pos 2 up to pos end-1 (i.e., before 1st cust up to after last cust)
                    newPosInRouteTemp = randi([2, length(route_temp)]);
                    
                    tempSolution{routeIdx} = [route_temp(1:newPosInRouteTemp-1), customerNode, route_temp(newPosInRouteTemp:end)];
                    operatorApplied = true;

                case 3 % 3. Relocate (Inter-route move a customer) - or create new route
                    if numRoutesWithAtLeastOneCust < 1 % Need at least one route to take a customer from
                        operatorType = selectFallBackOperatorType(operatorType, numRoutesWithAtLeastOneCust, numRoutesWithAtLeastTwoCust);
                        continue;
                    end
                    
                    eligibleRouteIndicesFrom = validRouteIndices(arrayfun(@(idx) length(tempSolution{idx}) - 2 >= 1, validRouteIndices));
                     if isempty(eligibleRouteIndicesFrom)
                        operatorType = selectFallBackOperatorType(operatorType, numRoutesWithAtLeastOneCust, numRoutesWithAtLeastTwoCust);
                        continue;
                    end
                    routeIdxFrom = datasample(eligibleRouteIndicesFrom, 1);
                    currentRouteIdxForDebug = routeIdxFrom;
                    routeFrom = tempSolution{routeIdxFrom};
                    numCustInRouteFrom = length(routeFrom) - 2;
                    
                    custIdxToMoveInRouteArray = datasample(2:(numCustInRouteFrom+1), 1);
                    customerNode = routeFrom(custIdxToMoveInRouteArray);

                    routeFrom_updated = routeFrom;
                    routeFrom_updated(custIdxToMoveInRouteArray) = [];
                    
                    probNewRoute = 0.2; % Probability to create a new route for the moved customer
                    possibleTargetRouteIndices = validRouteIndices(validRouteIndices ~= routeIdxFrom);
                    % Filter further: target routes must also be valid routes (e.g. not become [D,D] if only one cust was there)
                    possibleTargetRouteIndices = possibleTargetRouteIndices(arrayfun(@(idx) length(tempSolution{idx}) > 2, possibleTargetRouteIndices));


                    if rand() < probNewRoute || isempty(possibleTargetRouteIndices)
                        % Create a new route
                        newDepotForCust = routeFrom(1); % Use same depot as origin, or randi([1, numSelectedHubs])
                        newRoute = [newDepotForCust, customerNode, newDepotForCust];
                        
                        tempSolution{routeIdxFrom} = routeFrom_updated; % Update original route
                        
                        emptyCellIdx = find(cellfun(@(c) isempty(c) || length(c)<=2, tempSolution), 1);
                        if ~isempty(emptyCellIdx)
                            tempSolution{emptyCellIdx} = newRoute;
                        else
                            tempSolution{end+1} = newRoute;
                        end
                        operatorApplied = true;
                    else
                        % Move to another existing route
                        routeIdxTo = datasample(possibleTargetRouteIndices, 1);
                        routeTo = tempSolution{routeIdxTo};
                        
                        insertPosInRouteToArray = randi([2, length(routeTo)]); % Insert before this position (after depot, before end depot)
                        
                        tempSolution{routeIdxFrom} = routeFrom_updated;
                        tempSolution{routeIdxTo} = [routeTo(1:insertPosInRouteToArray-1), customerNode, routeTo(insertPosInRouteToArray:end)];
                        operatorApplied = true;
                    end

                case 4 % 4. Exchange (Inter-route swap of one customer from each of two routes)
                    if numRoutesWithAtLeastOneCust < 2 % Need at least two routes with customers
                        operatorType = selectFallBackOperatorType(operatorType, numRoutesWithAtLeastOneCust, numRoutesWithAtLeastTwoCust);
                        continue;
                    end
                    
                    eligibleRouteIndicesForSwap = validRouteIndices(arrayfun(@(idx) length(tempSolution{idx}) - 2 >= 1, validRouteIndices));
                    if length(eligibleRouteIndicesForSwap) < 2
                         operatorType = selectFallBackOperatorType(operatorType, numRoutesWithAtLeastOneCust, numRoutesWithAtLeastTwoCust);
                         continue;
                    end

                    selectedPairRouteIndices = datasample(eligibleRouteIndicesForSwap, 2, 'Replace', false);
                    routeIdx1 = selectedPairRouteIndices(1);
                    routeIdx2 = selectedPairRouteIndices(2);
                    currentRouteIdxForDebug = [routeIdx1, routeIdx2];

                    route1 = tempSolution{routeIdx1};
                    route2 = tempSolution{routeIdx2};
                    
                    numCustInRoute1 = length(route1) - 2;
                    numCustInRoute2 = length(route2) - 2;
                    
                    custIdxInRoute1Array = randi(numCustInRoute1) + 1; % Index in full route1 array
                    custIdxInRoute2Array = randi(numCustInRoute2) + 1; % Index in full route2 array
                    
                    tempCustNode = route1(custIdxInRoute1Array);
                    tempSolution{routeIdx1}(custIdxInRoute1Array) = route2(custIdxInRoute2Array);
                    tempSolution{routeIdx2}(custIdxInRoute2Array) = tempCustNode;
                    operatorApplied = true;
            end % end switch
        catch ME_neighbor
            fprintf('SA_Neighbor Warn: Error during op type %d (Route(s) involved: %s): %s. Retrying.\n', ...
                    operatorType, mat2str(currentRouteIdxForDebug), ME_neighbor.message);
            % disp(ME_neighbor.stack(1)); % For more detailed debugging
            operatorType = selectFallBackOperatorType(operatorType, numRoutesWithAtLeastOneCust, numRoutesWithAtLeastTwoCust);
            tempSolution = neighborSolution; % Reset to pre-attempt state to avoid cascading errors
        end % end try-catch

        if operatorApplied
            neighborSolution = tempSolution; % Commit successful change
            
            % --- Solution Cleaning ---
            % Remove routes that are now empty (only depot-depot) or invalid
            % A route is valid if: not empty, length > 2, starts/ends at a valid hub, and is same hub.
            
            finalCleanedSolution = {};
            originalNumSlots = numCustomers; % Try to maintain roughly this many potential route slots
            
            for k=1:length(neighborSolution)
                route_k = neighborSolution{k};
                if ~isempty(route_k) && length(route_k) > 2 && ...
                   route_k(1) >= 1 && route_k(1) <= numSelectedHubs && ...
                   route_k(end) >= 1 && route_k(end) <= numSelectedHubs && ...
                   route_k(1) == route_k(end)
                    % This route has customers and valid depot structure
                    finalCleanedSolution{end+1} = route_k;
                end
            end
            
            % Ensure there are enough empty cells for future new routes if needed,
            % up to a reasonable limit (e.g., numCustomers total routes max).
            if isempty(finalCleanedSolution) && numCustomers > 0
                neighborSolution = cell(1, originalNumSlots); % All empty
                neighborSolution(:) = {[]}; % Ensure they are truly empty cells
            elseif length(finalCleanedSolution) < originalNumSlots && numCustomers > 0
                numToAdd = originalNumSlots - length(finalCleanedSolution);
                finalCleanedSolution = [finalCleanedSolution, cell(1, numToAdd)];
                finalCleanedSolution( (end-numToAdd+1):end ) = {[]}; % Fill with empty cells
                neighborSolution = finalCleanedSolution;
            elseif ~isempty(finalCleanedSolution)
                 neighborSolution = finalCleanedSolution;
            else % Covers numCustomers == 0 case
                neighborSolution = {};
            end
        end % end if operatorApplied
    end % end while loop for attempts

    if ~operatorApplied && attempt == maxAttempts
        % fprintf('SA_Debug: Failed to apply any neighbor operator after %d attempts.\n', maxAttempts);
    end
end

function newOpType = selectFallBackOperatorType(currentOpType, numRoutesMinOneCust, numRoutesMinTwoCust)
% Fallback logic for neighborhood operator selection if an operator fails its preconditions.
    
    possibleOps = [];
    if numRoutesMinTwoCust >= 1 % At least one route suitable for 2-opt
        possibleOps = [possibleOps, 1];
    end
    if numRoutesMinOneCust >= 1 % At least one route suitable for intra-relocate
        possibleOps = [possibleOps, 2];
    end
    if numRoutesMinOneCust >= 1 % Suitable for inter-relocate (from)
        possibleOps = [possibleOps, 3];
    end
    if numRoutesMinOneCust >= 2 % Suitable for inter-exchange
        possibleOps = [possibleOps, 4];
    end

    if isempty(possibleOps)
        newOpType = currentOpType; % No valid operator, stick to current (likely won't proceed)
        return;
    end
    
    % Try to pick a different operator than the current one if possible
    alternativeOps = setdiff(possibleOps, currentOpType);
    if ~isempty(alternativeOps)
        newOpType = datasample(alternativeOps, 1);
    else
        newOpType = datasample(possibleOps, 1); % If currentOpType is the only valid one left
    end
end

function count = numRoutesWithMinCustomers(solution, validRouteIndices, minCust)
% Counts how many routes in validRouteIndices have at least 'minCust' customers.
    count = 0;
    if isempty(validRouteIndices), return; end
    
    for i = 1:length(validRouteIndices)
        idx = validRouteIndices(i);
        if idx <= length(solution) && ~isempty(solution{idx})
            if (length(solution{idx}) - 2) >= minCust
                count = count + 1;
            end
        end
    end
end