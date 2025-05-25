% File: Drone_Urban_Logistics_Platform/+path_planning_algorithms/+simulated_annealing_vrp/solve_SA_VRP.m

function [bestSolution, bestCost, costHistory, intermediateData] = solve_SA_VRP(paramsSA, droneParams, ...
                                                                  locations, demands, numSelectedHubs, ...
                                                                  ~, iterationCheckpoints, outputDirSA) % utils argument removed or marked as unused

% Solves the Multi-Depot Vehicle Routing Problem (MDVRP) using Simulated Annealing.
% No internal 'import' statements. All package functions called by full path.

    fprintf('\n--- Starting Simulated Annealing for VRP ---\n');
    numCustomers = size(locations, 1) - numSelectedHubs;
    numLocations = size(locations, 1);

    % --- Create Initial Solution ---
    currentSolution = path_planning_algorithms.simulated_annealing_vrp.generate_Initial_Solution_SA(numCustomers, numSelectedHubs, paramsSA.MaxIterPerTemp); %
    currentCost = path_planning_algorithms.simulated_annealing_vrp.calculate_Total_Cost_SA(currentSolution, locations, demands, droneParams, numSelectedHubs, struct()); % Pass empty struct for utils
    
    bestSolution = currentSolution;
    bestCost = currentCost;

    T = paramsSA.InitialTemp;
    totalIter = 0;
    if paramsSA.Alpha < 1 && paramsSA.InitialTemp > 0 && paramsSA.FinalTemp > 0 && paramsSA.InitialTemp > paramsSA.FinalTemp
        numTempLevels = ceil(log(paramsSA.FinalTemp/paramsSA.InitialTemp)/log(paramsSA.Alpha));
    else
        numTempLevels = 100; 
    end
    maxTotalIterEst = numTempLevels * paramsSA.MaxIterPerTemp * 1.2; 
    if maxTotalIterEst <= 0 || isinf(maxTotalIterEst) || isnan(maxTotalIterEst)
        maxTotalIterEst = 100000; 
    end
    costHistory = zeros(ceil(maxTotalIterEst), 1);
    
    intermediateData = struct('Iteration', num2cell(iterationCheckpoints), ...
                              'Solution', cell(1, length(iterationCheckpoints)), ...
                              'Cost', cell(1, length(iterationCheckpoints)), ...
                              'PlotFile', cell(1, length(iterationCheckpoints)), ...
                              'KMLFile', cell(1, length(iterationCheckpoints)));
    checkpointIdx = 1;

    fprintf('Initial Solution Cost: %.2f\n', currentCost);
    if isinf(currentCost) || isnan(currentCost)
        warning('SA:InitialCost', 'Initial SA solution cost is Inf or NaN. Check constraints or initial solution generation.');
    end

    tempLevel = 0;
    while T > paramsSA.FinalTemp && T > 0 && totalIter < ceil(maxTotalIterEst) 
        tempLevel = tempLevel + 1;
        iterSinceLastBest = 0;
        fprintf('SA Temp Level %d: %.4f, Current Cost: %.2f (Best: %.2f)\n', tempLevel, T, currentCost, bestCost);

        for iter = 1:paramsSA.MaxIterPerTemp
            totalIter = totalIter + 1;
            iterSinceLastBest = iterSinceLastBest + 1;

            if totalIter > length(costHistory) 
                costHistory = [costHistory; zeros(paramsSA.MaxIterPerTemp*10, 1)];
            end

            neighborSolution = path_planning_algorithms.simulated_annealing_vrp.generate_Neighbor_Solution_SA(currentSolution, numCustomers, numSelectedHubs, numLocations); %
            neighborCost = path_planning_algorithms.simulated_annealing_vrp.calculate_Total_Cost_SA(neighborSolution, locations, demands, droneParams, numSelectedHubs, struct()); % Pass empty struct for utils
            
            if isnan(neighborCost)
                fprintf('Warning: SA Neighbor cost is NaN at Total Iter %d. Skipping.\n', totalIter);
                if totalIter > 0, costHistory(totalIter) = bestCost; end 
                continue;
            end

            deltaCost = neighborCost - currentCost;
            accept = false;
            if deltaCost < 0
                accept = true;
            else
                if T > 1e-9 
                    acceptanceProb = exp(-deltaCost / T);
                    if rand() < acceptanceProb
                        accept = true;
                    end
                else 
                    accept = false;
                end
            end

            if accept
                currentSolution = neighborSolution;
                currentCost = neighborCost;
                if currentCost < bestCost
                    bestSolution = currentSolution;
                    bestCost = currentCost;
                    iterSinceLastBest = 0;
                    fprintf('  -> New SA Best Cost: %.2f at Iter %d (Temp: %.4f)\n', bestCost, totalIter, T);
                end
            end
            if totalIter > 0, costHistory(totalIter) = bestCost; end

            if checkpointIdx <= length(iterationCheckpoints) && totalIter == iterationCheckpoints(checkpointIdx)
                fprintf('SA: Reached checkpoint at iteration %d. Saving intermediate results.\n', totalIter);
                intermediateData(checkpointIdx).Solution = bestSolution; 
                intermediateData(checkpointIdx).Cost = bestCost;
                
                plotFileNameBase = fullfile(outputDirSA, sprintf('plot_sa_routes_iter_%04d', totalIter)); % leading zeros for better sorting
                
                % MODIFIED TITLE for intermediate SA snapshot
                snapshot_title = 'Simulated Annealing Intermediate Routes';
                fig_snapshot = path_planning_algorithms.visualizer_SA.plot_SA_Route_Snapshot(bestSolution, locations, numSelectedHubs, demands, droneParams, struct(), ... 
                                       snapshot_title, []); %
                
                if ~isempty(fig_snapshot) && ishandle(fig_snapshot)
                   common_utilities.save_Figure_Properly(fig_snapshot, plotFileNameBase, {'png','fig'}); %
                   close(fig_snapshot); 
                   intermediateData(checkpointIdx).PlotFile = [plotFileNameBase, '.png']; 
                else
                   intermediateData(checkpointIdx).PlotFile = '';
                end
                
                intermediateData(checkpointIdx).KMLFile = ''; 
                                
                checkpointIdx = checkpointIdx + 1;
            end
            
        end
        T = T * paramsSA.Alpha; 
        if paramsSA.Alpha >= 1 && tempLevel > 1 
            fprintf('Warning: SA Alpha is >= 1. Halting cooling.\n');
            break;
        end
    end

    if totalIter > 0
        costHistory = costHistory(1:totalIter); 
    else
        costHistory = []; 
    end
    
    if iscell(bestSolution)
        bestSolution = bestSolution(cellfun(@(r) ~isempty(r) && length(r) > 2, bestSolution));
    end

    fprintf('SA Finished. Final Best Cost: %.2f after %d total iterations.\n', bestCost, totalIter);
end