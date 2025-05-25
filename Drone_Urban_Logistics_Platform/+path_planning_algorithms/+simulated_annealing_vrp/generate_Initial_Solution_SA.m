% File: Drone_Urban_Logistics_Platform/+path_planning_algorithms/+simulated_annealing_vrp/generate_Initial_Solution_SA.m
function initialSolution = generate_Initial_Solution_SA(numCustomers, numSelectedHubs, ~) % K_iter_unused for now
% Generates a simple initial solution for SA: one route per customer from a random hub.
%
% INPUTS:
%   numCustomers (integer): Total number of customers.
%   numSelectedHubs (integer): Number of available hubs/depots.
%   K_iter_unused (integer): Placeholder, was maxIterPerTemp, not directly used here for this simple strategy.
%
% OUTPUTS:
%   initialSolution (cell array): Each cell contains a route [hubIdx, customerIdx, hubIdx].
%                                 customerIdx is relative to the combined locations array.

    if numCustomers == 0
        initialSolution = {};
        return;
    end
    if numSelectedHubs == 0
        error('generate_Initial_Solution_SA:NoHubs', 'Cannot generate initial solution with zero hubs.');
    end

    initialSolution = cell(numCustomers, 1);
    for i = 1:numCustomers
        % Assign customer to a random hub
        depotIdx = randi([1, numSelectedHubs]); % Hub indices are 1 to numSelectedHubs
        customerGlobalIdx = numSelectedHubs + i;  % Customer index in the combined 'locations' array
        initialSolution{i} = [depotIdx, customerGlobalIdx, depotIdx];
    end
    % fprintf('SA: Generated Initial Solution with %d routes (one per customer).\n', numCustomers);
end