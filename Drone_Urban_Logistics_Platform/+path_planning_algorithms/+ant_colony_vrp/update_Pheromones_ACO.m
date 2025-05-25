% File: Drone_Urban_Logistics_Platform/+path_planning_algorithms/+ant_colony_vrp/update_Pheromones_ACO.m
function pheromoneTrails = update_Pheromones_ACO(pheromoneTrails, antSolutions, antCosts, ...
    globalBestSolution, globalBestCost, paramsACO, numLocations)
% Updates pheromone trails based on ant solutions.
% Implements evaporation and pheromone deposit.
% Uses an Elitist Ant System approach: global best solution gets extra reinforcement.

    % --- Pheromone Evaporation ---
    pheromoneTrails = (1 - paramsACO.Rho_Evaporation) * pheromoneTrails;
    % Ensure pheromones don't go below a minimum threshold (tau_min) to encourage exploration
    tau_min = paramsACO.Tau0_InitialPheromone / (2*numLocations); % Example for tau_min
    pheromoneTrails(pheromoneTrails < tau_min) = tau_min;

    % --- Pheromone Deposit by all ants (or iteration best) ---
    % Here, for simplicity, all ants contribute based on their solution quality.
    % A common alternative is only the iteration-best ant deposits pheromones.
    for k = 1:length(antSolutions)
        if isinf(antCosts(k)) || isnan(antCosts(k)) || antCosts(k) == 0, continue; end % Skip invalid or zero-cost solutions

        delta_tau_k = paramsACO.Q_PheromoneFactor / antCosts(k); % Pheromone amount related to solution quality
        solution_k = antSolutions{k};
        
        for r = 1:length(solution_k) % For each route in the ant's solution
            route = solution_k{r};
            if isempty(route) || length(route) < 2, continue; end
            for leg = 1:(length(route) - 1)
                loc_i = route(leg);
                loc_j = route(leg+1);
                pheromoneTrails(loc_i, loc_j) = pheromoneTrails(loc_i, loc_j) + delta_tau_k;
                % For symmetric problems, often tau(j,i) is also updated, but VRP is directed.
                % If you want symmetric update for undirected graph feel:
                % pheromoneTrails(loc_j, loc_i) = pheromoneTrails(loc_j, loc_i) + delta_tau_k;
            end
        end
    end
    
    % --- Elitist Update: Additional pheromone deposit for the global best solution ---
    if ~isinf(globalBestCost) && globalBestCost > 0 && ~isempty(globalBestSolution)
        % 'e' is the number of elite ants, or an elitist weight factor.
        % Here, we use a weight factor for the global best solution.
        elitistWeightFactor = paramsACO.NumAnts * 0.5; % Example: Global best gets as much pheromone as half the colony depositing based on its cost
        delta_tau_global_best = elitistWeightFactor * (paramsACO.Q_PheromoneFactor / globalBestCost);
        
        for r = 1:length(globalBestSolution)
            route = globalBestSolution{r};
            if isempty(route) || length(route) < 2, continue; end
            for leg = 1:(length(route) - 1)
                loc_i = route(leg);
                loc_j = route(leg+1);
                pheromoneTrails(loc_i, loc_j) = pheromoneTrails(loc_i, loc_j) + delta_tau_global_best;
            end
        end
    end
    
    % Optional: Pheromone smoothing or max-min limits
    tau_max = paramsACO.Q_PheromoneFactor / (paramsACO.Rho_Evaporation * globalBestCost); % Estimate of max pheromone if globalBestCost is near optimal
    if ~isinf(tau_max) && tau_max > 0
       pheromoneTrails(pheromoneTrails > tau_max) = tau_max;
    end

end