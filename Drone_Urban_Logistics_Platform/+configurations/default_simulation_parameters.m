% File: Drone_Urban_Logistics_Platform/configurations/default_simulation_parameters.m
% Defines the default parameters for the drone logistics simulation.
% This script is called by DroneLogisticsConfigurator.mlapp to populate UI fields.

function params = default_simulation_parameters()
    % -------------------------------------------------------------------------
    % Scenario & Location Parameters 🏞️
    % -------------------------------------------------------------------------
    params.Scenario.CenterLatitude = 36.0611;   % Default: Lanzhou Latitude
    params.Scenario.CenterLongitude = 103.8343;  % Default: Lanzhou Longitude
    params.Scenario.MapRadiusKm = 5.0;         % Approx. 5km radius for customer/depot generation
    params.Scenario.NumCustomers = 50;         % Default number of customers
    params.Scenario.NumCandidateDepots = 20;   % Default number of candidate depots to generate
    params.Scenario.NumHubsToSelect = 5;       % Default number of hubs/depots to be selected

    % -------------------------------------------------------------------------
    % Drone Parameters 🚁
    % -------------------------------------------------------------------------
    params.Drone.PayloadCapacity = 10; % Units (e.g., packages, kg)
    params.Drone.MaxRangeKm = 15.0;    % Maximum flight range on a full charge (km)
    params.Drone.UnitCostPerKm = 0.5;  % Cost per kilometer (e.g., RMB/km)

    % -------------------------------------------------------------------------
    % Simulated Annealing (SA) Parameters 🔥
    % -------------------------------------------------------------------------
    params.SA.InitialTemp = 1000;     % Initial temperature
    params.SA.FinalTemp = 0.1;        % Final temperature
    params.SA.Alpha = 0.98;           % Cooling rate (geometric cooling)
    params.SA.MaxIterPerTemp = 250;   % Iterations at each temperature level (Markov chain length)

    % -------------------------------------------------------------------------
    % Ant Colony Optimization (ACO) Parameters 🐜
    % -------------------------------------------------------------------------
    params.ACO.NumAnts = 30;                    % Number of ants
    params.ACO.MaxIterations = 100;             % Maximum number of iterations for ACO
    params.ACO.Rho_Evaporation = 0.1;           % Pheromone evaporation rate (0 < rho <= 1)
    params.ACO.Alpha_PheromoneImportance = 1.0; % Pheromone importance factor (typically >= 0)
    params.ACO.Beta_HeuristicImportance = 2.0;  % Heuristic information importance factor (typically >= 0)
    params.ACO.Tau0_InitialPheromone = 0.1;     % Initial pheromone level on all paths

    % -------------------------------------------------------------------------
    % Visualization & Reporting Parameters 📊
    % (These might not be set in the UI but are useful for main_Orchestrator)
    % -------------------------------------------------------------------------
    params.Output.SaveFigures = true;       % Master switch to save plots
    params.Output.SaveKML = true;           % Master switch to save KML files
    params.Output.IntermediatePlotIterations = [5]; % Define specific iteration numbers for snapshots
                                                    % The 1/3, 2/3, final will be calculated in main_Orchestrator
    params.Output.ResultsBaseFolder = 'results_output'; % Name of the main results folder

    fprintf('Default simulation parameters loaded.\n');
end