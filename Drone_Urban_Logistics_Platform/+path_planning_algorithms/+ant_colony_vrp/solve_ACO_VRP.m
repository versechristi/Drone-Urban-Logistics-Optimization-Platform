% File: Drone_Urban_Logistics_Platform/+path_planning_algorithms/+ant_colony_vrp/solve_ACO_VRP.m
function [globalBestSolution, globalBestCost, costHistory, intermediateData] = solve_ACO_VRP(paramsACO, droneParams, ...
    locations, demands, numSelectedHubs, ~, iterationCheckpoints, outputDirACO) % MODIFIED: Re-added '~' for unused utils argument (6th argument)
% Solves the Multi-Depot Vehicle Routing Problem (MDVRP) using Ant Colony Optimization.
%
% INPUTS:
%   paramsACO (struct): Parameters for ACO.
%   droneParams (struct): Drone specifications.
%   locations (Nx2 matrix): Coordinates.
%   demands (Mx1 vector): Customer demands.
%   numSelectedHubs (integer): Number of active hubs.
%   ~ (any, optional): Unused argument (formerly utils).
%   iterationCheckpoints (vector): Iteration numbers to save intermediate results.
%   outputDirACO (string): Path to save ACO plots and data.
%
% OUTPUTS:
%   globalBestSolution (cell array): Best set of routes found.
%   globalBestCost (double): Cost of the best solution.
%   costHistory (vector): Cost of the best solution found at each iteration.
%   intermediateData (struct array): Data saved at checkpoints.

    fprintf('\n--- Starting Ant Colony Optimization for VRP ---\n');

    numLocations = size(locations, 1);
    numCustomers = numLocations - numSelectedHubs;

    if numCustomers == 0
        fprintf('ACO: No customers to serve. Exiting.\n');
        globalBestSolution = {};
        globalBestCost = 0;
        costHistory = [];
        intermediateData = struct('Iteration', {}, 'Solution', {}, 'Cost', {}, 'PlotFile', {}, 'KMLFile', {});
        return;
    end
    
    if ~isfield(paramsACO, 'Q_PheromoneFactor')
        paramsACO.Q_PheromoneFactor = 100; 
    end

    pheromoneTrails = ones(numLocations, numLocations) * paramsACO.Tau0_InitialPheromone;
    pheromoneTrails(logical(eye(numLocations))) = 0;
    for i = 1:numSelectedHubs
        for j = 1:numSelectedHubs
            if i ~= j
                pheromoneTrails(i,j) = 0; 
                pheromoneTrails(j,i) = 0;
            end
        end
    end

    heuristicInfo = zeros(numLocations, numLocations);
    for i = 1:numLocations
        for j = 1:numLocations
            if i == j
                heuristicInfo(i, j) = 0;
            else
                dist = common_utilities.calculate_Haversine_Distance(locations(i,1), locations(i,2), locations(j,1), locations(j,2)); % Direct call
                if dist == 0 
                    heuristicInfo(i,j) = 1e6; 
                else
                    heuristicInfo(i, j) = 1 / dist;
                end
            end
        end
    end

    globalBestSolution = {};
    globalBestCost = inf;
    costHistory = zeros(paramsACO.MaxIterations, 1);

    intermediateData = struct('Iteration', num2cell(iterationCheckpoints), ...
                              'Solution', cell(1, length(iterationCheckpoints)), ...
                              'Cost', cell(1, length(iterationCheckpoints)), ...
                              'PlotFile', cell(1, length(iterationCheckpoints)), ...
                              'KMLFile', cell(1, length(iterationCheckpoints)));
    checkpointIdx = 1;
    
    for iter = 1:paramsACO.MaxIterations
        fprintf('ACO Iteration %d/%d:  Global Best Cost: %.2f\n', iter, paramsACO.MaxIterations, globalBestCost);
        
        iterationBestSolution = {};
        iterationBestCost = inf;
        
        antSolutions = cell(paramsACO.NumAnts, 1);
        antCosts = inf(paramsACO.NumAnts, 1);

        for k_ant = 1:paramsACO.NumAnts
            [ant_k_Solution, ant_k_Cost] = ...
                path_planning_algorithms.ant_colony_vrp.ants_Construct_Solutions_ACO(k_ant, pheromoneTrails, heuristicInfo, ...
                                                                      locations, demands, numSelectedHubs, ...
                                                                      droneParams, paramsACO); 
            antSolutions{k_ant} = ant_k_Solution;
            antCosts(k_ant) = ant_k_Cost;
        end

        for k_ant_eval = 1:paramsACO.NumAnts
            if antCosts(k_ant_eval) < iterationBestCost
                iterationBestCost = antCosts(k_ant_eval);
                iterationBestSolution = antSolutions{k_ant_eval};
            end
        end
        
        if iterationBestCost < globalBestCost
            globalBestCost = iterationBestCost;
            globalBestSolution = iterationBestSolution;
            fprintf('  ** New Global Best Found by ACO: %.2f at iteration %d **\n', globalBestCost, iter);
        end
        costHistory(iter) = globalBestCost;

        pheromoneTrails = path_planning_algorithms.ant_colony_vrp.update_Pheromones_ACO(pheromoneTrails, antSolutions, antCosts, ...
                                                globalBestSolution, globalBestCost, paramsACO, numLocations);
        
        if checkpointIdx <= length(iterationCheckpoints) && iter == iterationCheckpoints(checkpointIdx)
            fprintf('ACO: Reached checkpoint at iteration %d. Saving intermediate results.\n', iter);
            intermediateData(checkpointIdx).Solution = globalBestSolution;
            intermediateData(checkpointIdx).Cost = globalBestCost;
            
            plotFileBasePath = fullfile(outputDirACO, sprintf('plot_aco_routes_iter_%04d', iter)); % leading zeros
            
            % MODIFIED TITLE for intermediate ACO snapshot
            snapshot_title = 'Ant Colony Optimization Intermediate Routes';
            fig_snapshot_aco = path_planning_algorithms.ant_colony_vrp.visualizer_ACO.plot_ACO_Route_Snapshot(globalBestSolution, locations, numSelectedHubs, demands, droneParams, struct(), ... 
                                   snapshot_title, []); %
            
            if ~isempty(fig_snapshot_aco) && ishandle(fig_snapshot_aco)
                common_utilities.save_Figure_Properly(fig_snapshot_aco, plotFileBasePath, {'png','fig'});
                intermediateData(checkpointIdx).PlotFile = [plotFileBasePath, '.png'];
                if ishandle(fig_snapshot_aco), close(fig_snapshot_aco); end
            else
                intermediateData(checkpointIdx).PlotFile = '';
                 warning('solve_ACO_VRP:PlottingError', 'Failed to generate or save ACO snapshot plot for iter %d.', iter);
            end
            
            intermediateData(checkpointIdx).KMLFile = ''; 
            checkpointIdx = checkpointIdx + 1;
        end
    end 

    fprintf('ACO Finished. Final Global Best Cost: %.2f after %d iterations.\n', globalBestCost, paramsACO.MaxIterations);
end