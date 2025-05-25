% File: Drone_Urban_Logistics_Platform/main_Orchestrator.m
% Main script to orchestrate the entire drone logistics simulation pipeline.

function main_Orchestrator()
    %% --- 0. Setup Environment & Clear Previous ---
    clc; close all; 
    fprintf('============================================================\n');
    fprintf('      DRONE URBAN LOGISTICS OPTIMIZATION PLATFORM      \n');
    fprintf('============================================================\n');
    fprintf('Orchestrator started at: %s\n', datestr(now, 'yyyy-mm-dd HH:MM:SS'));

    % --- BEGIN MODIFICATION: Enhanced Path Setup ---
    scriptFullPath = mfilename('fullpath');
    projectBasePath = fileparts(scriptFullPath); % Assumes main_Orchestrator.m is in the project root
    fprintf('Project Base Path detected as: %s\n', projectBasePath);
    originalPath = cd(projectBasePath); % Ensure current directory is the project root and save original path
    
    % Add project base path and all its subdirectories, then rehash
    addpath(genpath(projectBasePath)); % Add all subfolders of the project
    
    rehash toolboxcache; 
    rehash path; % Also rehash the path itself
    fprintf('Project paths (including subdirectories) added and caches rehashed.\n');
    % --- END MODIFICATION ---
    
    configPath = fullfile(projectBasePath, 'configurations');
    if ~exist(configPath, 'dir')
        warning('main_Orchestrator:ConfigPath', 'Configuration directory not found: %s', configPath);
    end
    
    timestamp = datestr(now, 'yyyymmdd_HHMMSS');
    experimentName = ['ExperimentRun_', timestamp]; 
    resultsPath = fullfile(projectBasePath, 'results_output', experimentName);
    if ~exist(resultsPath, 'dir'), mkdir(resultsPath); end
    if ~exist(fullfile(resultsPath, 'inputs'), 'dir'), mkdir(fullfile(resultsPath, 'inputs')); end
    if ~exist(fullfile(resultsPath, 'hub_layout_results'), 'dir'), mkdir(fullfile(resultsPath, 'hub_layout_results')); end
    if ~exist(fullfile(resultsPath, 'path_planning_sa'), 'dir'), mkdir(fullfile(resultsPath, 'path_planning_sa')); end
    if ~exist(fullfile(resultsPath, 'path_planning_aco'), 'dir'), mkdir(fullfile(resultsPath, 'path_planning_aco')); end
    if ~exist(fullfile(resultsPath, 'comparative_analysis_plots'), 'dir'), mkdir(fullfile(resultsPath, 'comparative_analysis_plots')); end

    diary(fullfile(resultsPath, 'simulation_log.txt')); 

    %% --- 1. Load Simulation Parameters ---
    fprintf('\n--- 1. Loading Simulation Parameters ---\n');
    paramsFile = fullfile(projectBasePath, 'configurations', 'current_run_parameters.mat'); 
    if exist(paramsFile, 'file')
        try
            loadedData = load(paramsFile, 'params'); 
            if isfield(loadedData, 'params')
                params = loadedData.params;
                fprintf('Loaded parameters from "current_run_parameters.mat" (set by UI).\n');
            else
                fprintf('WARNING: "current_run_parameters.mat" does not contain "params" variable. Loading default parameters.\n');
                params = configurations.default_simulation_parameters(); %
            end
        catch ME_load
            fprintf('WARNING: Error loading "current_run_parameters.mat": %s\n', ME_load.message);
            fprintf('Loading default parameters instead.\n');
            params = configurations.default_simulation_parameters(); %
        end
    else
        fprintf('INFO: "current_run_parameters.mat" not found. Loading default parameters.\n'); 
        params = configurations.default_simulation_parameters(); %
    end
    
    save(fullfile(resultsPath, 'inputs', 'parameters_used.mat'), 'params');
    disp('Using Parameters:');
    disp(params);

    scenarioParams = params.Scenario;
    droneParams    = params.Drone;
    saAlgoParams   = params.SA;
    acoAlgoParams  = params.ACO;
    
    if isfield(params, 'Output')
        outputParams = params.Output;
    else
        fprintf('INFO: Output parameters not found in params struct, using defaults for Output.\n');
        outputParams.SaveFigures = true;
        outputParams.SaveKML = true;
        outputParams.IntermediatePlotIterations = [5];
    end

    %% --- 2. Data Generation ---
    fprintf('\n--- 2. Generating Scenario Data ---\n'); 
    rng('default'); rng(1); 
    customers = data_generation.generate_Customers(scenarioParams); %
    candidateDepots = data_generation.generate_Candidate_Depots(scenarioParams); %
    droneSpecs = data_generation.load_Drone_Specifications(droneParams); %

    if isempty(customers)
        fprintf('No customers generated. Aborting simulation.\n');
        diary off; cd(originalPath); return; 
    end
    if isempty(candidateDepots) && scenarioParams.NumHubsToSelect > 0
        fprintf('No candidate depots generated, but hubs need to be selected. Aborting.\n');
        diary off; cd(originalPath); return; 
    end

    %% --- 3. Hub Selection and Layout ---
    fprintf('\n--- 3. Optimizing Hub Locations ---\n'); 
    if scenarioParams.NumHubsToSelect > 0
        selectedHubs = hub_selection_layout.optimize_Hub_Locations(customers, candidateDepots, scenarioParams.NumHubsToSelect, struct()); %
        if isempty(selectedHubs) || length(selectedHubs) < scenarioParams.NumHubsToSelect
            fprintf('WARNING: Could not select the desired number of hubs (%d requested, %d selected). Check data or hub selection logic.\n', ...
                scenarioParams.NumHubsToSelect, length(selectedHubs));
            if isempty(selectedHubs)
                 fprintf('Aborting due to no hubs selected.\n'); diary off; cd(originalPath); return; 
            end
        end

        % MODIFIED TITLE
        hub_plot_title1 = 'Candidate Depots and Selected Hubs';
        fig_hub1 = hub_selection_layout.visualizer.plot_Candidate_Vs_Selected_Hubs(candidateDepots, selectedHubs, customers, scenarioParams, hub_plot_title1); %
        
        if outputParams.SaveFigures
            if ~isempty(fig_hub1) && ishandle(fig_hub1)
                common_utilities.save_Figure_Properly(fig_hub1, fullfile(resultsPath, 'hub_layout_results', 'plot_candidate_vs_selected_hubs'), {'png', 'fig'}); %
                if ishandle(fig_hub1) 
                    close(fig_hub1);
                else
                    fprintf('WARNING (main_Orchestrator): fig_hub1 became invalid after save_Figure_Properly, cannot close.\n');
                end
            elseif ~isempty(fig_hub1) && ~ishandle(fig_hub1)
                 fprintf('WARNING (main_Orchestrator): fig_hub1 was returned as non-empty but is an invalid handle. Cannot save or close.\n');
            else 
                 fprintf('INFO (main_Orchestrator): fig_hub1 is empty or invalid from plot_Candidate_Vs_Selected_Hubs. Skipping save and close.\n');
            end
        elseif ~isempty(fig_hub1) && ishandle(fig_hub1) 
            set(fig_hub1, 'Visible', 'on');
        elseif ~isempty(fig_hub1) && ~ishandle(fig_hub1)
             fprintf('WARNING (main_Orchestrator): fig_hub1 was returned as non-empty but is an invalid handle. Cannot show.\n');
        end

        layoutMetrics = hub_selection_layout.evaluate_Hub_Layout_Fitness(selectedHubs, customers, struct()); %
        % MODIFIED TITLE
        hub_plot_title2 = 'Hub Service Areas (Nearest Hub)';
        fig_hub2 = hub_selection_layout.visualizer.plot_Hub_Service_Areas(selectedHubs, customers, layoutMetrics.CustomerAssignmentsToHubID, scenarioParams, hub_plot_title2); %
        
        if outputParams.SaveFigures
            if ~isempty(fig_hub2) && ishandle(fig_hub2) 
                common_utilities.save_Figure_Properly(fig_hub2, fullfile(resultsPath, 'hub_layout_results', 'plot_hub_service_areas'), {'png', 'fig'}); %
                if ishandle(fig_hub2) 
                    close(fig_hub2);
                else
                    fprintf('WARNING (main_Orchestrator): fig_hub2 became invalid after save_Figure_Properly, cannot close.\n');
                end
            elseif ~isempty(fig_hub2) && ~ishandle(fig_hub2)
                 fprintf('WARNING (main_Orchestrator): fig_hub2 was returned as non-empty but is an invalid handle. Cannot save or close.\n');
            else 
                 fprintf('INFO (main_Orchestrator): fig_hub2 is empty or invalid from plot_Hub_Service_Areas. Skipping save and close.\n');
            end
        elseif ~isempty(fig_hub2) && ishandle(fig_hub2) 
            set(fig_hub2, 'Visible', 'on');
        elseif ~isempty(fig_hub2) && ~ishandle(fig_hub2)
             fprintf('WARNING (main_Orchestrator): fig_hub2 was returned as non-empty but is an invalid handle. Cannot show.\n');
        end
        
        hub_selection_layout.visualizer.export_Hub_Layout_Data(selectedHubs, fullfile(resultsPath, 'hub_layout_results', 'selected_hubs_data')); %
    else
        fprintf('Number of hubs to select is 0. Skipping hub selection.\n');
        selectedHubs = struct('ID', {}, 'Latitude', {}, 'Longitude', {}); 
    end

    if scenarioParams.NumHubsToSelect > 0 && isempty(selectedHubs)
        fprintf('ERROR: Hub selection was supposed to run but returned no hubs. Aborting path planning.\n');
        diary off; cd(originalPath); return; 
    end

    %% --- 4. Path Planning Algorithms ---
    fprintf('\n--- 4. Running Path Planning Algorithms ---\n'); 

    if ~isempty(selectedHubs) && isfield(selectedHubs, 'Latitude') && isfield(selectedHubs, 'Longitude')
        hub_coords = [vertcat(selectedHubs.Latitude), vertcat(selectedHubs.Longitude)];
    else
        hub_coords = zeros(0,2); 
    end

    if ~isempty(customers) && isfield(customers, 'Latitude') && isfield(customers, 'Longitude')
        customer_coords = [vertcat(customers.Latitude), vertcat(customers.Longitude)];
        customer_demands = [vertcat(customers.Demand)]; 
    else
        customer_coords = zeros(0,2);
        customer_demands = [];
    end
    combined_locations = [hub_coords; customer_coords];

    sa_finalResults = struct('Cost', inf, 'Solution', {{}}, 'ComputationTime', 0, 'NumRoutes', 0, 'TotalDistance', 0, 'AvgCustomersPerRoute',0, 'CostHistory', []);
    aco_finalResults = struct('Cost', inf, 'Solution', {{}}, 'ComputationTime', 0, 'NumRoutes', 0, 'TotalDistance', 0, 'AvgCustomersPerRoute',0, 'CostHistory', []);

    if isempty(customers) || scenarioParams.NumHubsToSelect == 0 
        fprintf('Skipping path planning as there are no customers or no hubs selected.\n');
    else
        numActiveHubs = size(hub_coords, 1); 

        fprintf('\n--- 4.1 Running Simulated Annealing (SA) ---\n'); 
        total_sa_iterations = ceil(log(saAlgoParams.FinalTemp/saAlgoParams.InitialTemp)/log(saAlgoParams.Alpha)) * saAlgoParams.MaxIterPerTemp;
        if isinf(total_sa_iterations) || isnan(total_sa_iterations) || total_sa_iterations <=0 
            fprintf('Warning: SA total iterations could not be estimated reliably. Using default for checkpoints.\n');
            total_sa_iterations = saAlgoParams.MaxIterPerTemp * 100; % Fallback
        end
        sa_checkpoints = common_utilities.manage_Iteration_Checkpoints(total_sa_iterations, outputParams.IntermediatePlotIterations); %

        tic_sa = tic;
        [sa_bestSolution, sa_bestCost, sa_costHistory, sa_intermediateData] = ...
            path_planning_algorithms.simulated_annealing_vrp.solve_SA_VRP(... 
                saAlgoParams, droneSpecs, combined_locations, customer_demands, numActiveHubs, ...
                struct(), sa_checkpoints, fullfile(resultsPath, 'path_planning_sa')); 
        sa_finalResults.ComputationTime = toc(tic_sa);
        sa_finalResults.Cost = sa_bestCost;
        sa_finalResults.Solution = sa_bestSolution;
        sa_finalResults.CostHistory = sa_costHistory;
        
        [sa_finalResults.NumRoutes, sa_finalResults.TotalDistance, sa_finalResults.AvgCustomersPerRoute] = ...
            calculateSolutionMetrics(sa_bestSolution, combined_locations, numActiveHubs, struct()); 
        
        % MODIFIED TITLE for SA Final Routes plot
        fig_sa_final_title = 'Simulated Annealing Final Routes';
        fig_sa_final = path_planning_algorithms.visualizer_SA.plot_SA_Route_Snapshot(...
            sa_bestSolution, combined_locations, numActiveHubs, customer_demands, droneSpecs, struct(), ...
            fig_sa_final_title, []); %
        if outputParams.SaveFigures && ~isempty(fig_sa_final) && ishandle(fig_sa_final)
            common_utilities.save_Figure_Properly(fig_sa_final, fullfile(resultsPath, 'path_planning_sa', 'plot_sa_final_routes'), {'png', 'fig'});
            if ishandle(fig_sa_final), close(fig_sa_final); end
        elseif ~isempty(fig_sa_final) && ishandle(fig_sa_final)
            set(fig_sa_final, 'Visible', 'on');
        end
        
        if outputParams.SaveKML && ~isempty(sa_bestSolution)
             common_utilities.export_Routes_to_KML(sa_bestSolution, combined_locations, customer_demands, numActiveHubs, ... 
                                     customers, selectedHubs, ... 
                                     fullfile(resultsPath, 'path_planning_sa', 'routes_sa_final.kml'), ...
                                     ['SA Final - ', experimentName]); % KML description can retain experimentName
        end
        
        % REMOVED individual SA convergence plot generation
        
        save(fullfile(resultsPath, 'path_planning_sa', 'sa_results_data.mat'), 'sa_finalResults', 'sa_intermediateData', 'saAlgoParams');
        fprintf('SA run completed. Time: %.2f s, Cost: %.2f\n', sa_finalResults.ComputationTime, sa_finalResults.Cost);

        fprintf('\n--- 4.2 Running Ant Colony Optimization (ACO) ---\n');
        total_aco_iterations = acoAlgoParams.MaxIterations;
        aco_checkpoints = common_utilities.manage_Iteration_Checkpoints(total_aco_iterations, outputParams.IntermediatePlotIterations);

        tic_aco = tic;
        [aco_bestSolution, aco_bestCost, aco_costHistory, aco_intermediateData] = ...
            path_planning_algorithms.ant_colony_vrp.solve_ACO_VRP(...
                acoAlgoParams, droneSpecs, combined_locations, customer_demands, numActiveHubs, ...
                struct(), aco_checkpoints, fullfile(resultsPath, 'path_planning_aco'));
        aco_finalResults.ComputationTime = toc(tic_aco);
        aco_finalResults.Cost = aco_bestCost;
        aco_finalResults.Solution = aco_bestSolution;
        aco_finalResults.CostHistory = aco_costHistory;

        [aco_finalResults.NumRoutes, aco_finalResults.TotalDistance, aco_finalResults.AvgCustomersPerRoute] = ...
            calculateSolutionMetrics(aco_bestSolution, combined_locations, numActiveHubs, struct());

        % MODIFIED TITLE for ACO Final Routes plot
        fig_aco_final_title = 'Ant Colony Optimization Final Routes';
        fig_aco_final = path_planning_algorithms.ant_colony_vrp.visualizer_ACO.plot_ACO_Route_Snapshot(...
            aco_bestSolution, combined_locations, numActiveHubs, customer_demands, droneSpecs, struct(), ...
            fig_aco_final_title, []); %
        if outputParams.SaveFigures && ~isempty(fig_aco_final) && ishandle(fig_aco_final)
            common_utilities.save_Figure_Properly(fig_aco_final, fullfile(resultsPath, 'path_planning_aco', 'plot_aco_final_routes'), {'png', 'fig'});
            if ishandle(fig_aco_final), close(fig_aco_final); end
        elseif ~isempty(fig_aco_final) && ishandle(fig_aco_final)
            set(fig_aco_final, 'Visible', 'on');
        end

        if outputParams.SaveKML && ~isempty(aco_bestSolution)
             common_utilities.export_Routes_to_KML(aco_bestSolution, combined_locations, customer_demands, numActiveHubs, ...
                                     customers, selectedHubs, ...
                                     fullfile(resultsPath, 'path_planning_aco', 'routes_aco_final.kml'), ...
                                     ['ACO Final - ', experimentName]); % KML description can retain experimentName
        end
        
        % REMOVED individual ACO convergence plot generation
        
        save(fullfile(resultsPath, 'path_planning_aco', 'aco_results_data.mat'), 'aco_finalResults', 'aco_intermediateData', 'acoAlgoParams');
        fprintf('ACO run completed. Time: %.2f s, Cost: %.2f\n', aco_finalResults.ComputationTime, aco_finalResults.Cost);
    end 

    %% --- 5. Comparative Analytics ---
    fprintf('\n--- 5. Generating Comparative Analytics ---\n');
    if ~isempty(customers) && scenarioParams.NumHubsToSelect > 0 && ...
       isfield(sa_finalResults, 'Cost') && isfield(aco_finalResults, 'Cost') && ... 
       ~isinf(sa_finalResults.Cost) && ~isinf(aco_finalResults.Cost) 
        
        % MODIFIED TITLE for combined convergence plot
        comp_conv_title = 'SA vs. ACO Convergence';
        fig_comp_conv = comparative_analytics.plot_SA_vs_ACO_Convergence(sa_finalResults.CostHistory, aco_finalResults.CostHistory, comp_conv_title, []); %
        if outputParams.SaveFigures && ~isempty(fig_comp_conv) && ishandle(fig_comp_conv)
            common_utilities.save_Figure_Properly(fig_comp_conv, fullfile(resultsPath, 'comparative_analysis_plots', 'plot_convergence_comparison'), {'png', 'fig'});
            if ishandle(fig_comp_conv), close(fig_comp_conv); end
        elseif ~isempty(fig_comp_conv) && ishandle(fig_comp_conv)
            set(fig_comp_conv, 'Visible', 'on');
        end

        % MODIFIED TITLE for final performance bars
        comp_bar_title = 'SA vs. ACO Final Performance';
        fig_comp_bar = comparative_analytics.plot_Final_Performance_Bars(sa_finalResults, aco_finalResults, comp_bar_title, []); %
        if outputParams.SaveFigures && ~isempty(fig_comp_bar) && ishandle(fig_comp_bar)
            common_utilities.save_Figure_Properly(fig_comp_bar, fullfile(resultsPath, 'comparative_analysis_plots', 'plot_final_performance_bars'), {'png', 'fig'});
            if ishandle(fig_comp_bar), close(fig_comp_bar); end
        elseif ~isempty(fig_comp_bar) && ishandle(fig_comp_bar)
            set(fig_comp_bar, 'Visible', 'on');
        end
        
        comparative_analytics.generate_Comparative_Report(sa_finalResults, aco_finalResults, ...
            saAlgoParams, acoAlgoParams, scenarioParams, droneParams, ...
            fullfile(resultsPath, 'comparative_report.txt'));
    else
        fprintf('Skipping comparative analytics as path planning was not fully executed or did not yield valid comparable results.\n');
    end

    %% --- 6. Finalize ---
    fprintf('\n--- Simulation Run "%s" Completed ---\n', experimentName);
    fprintf('All results saved to: %s\n', resultsPath);
    fprintf('Orchestrator finished at: %s\n', datestr(now, 'yyyy-mm-dd HH:MM:SS'));
    diary off; 
    cd(originalPath); % Restore original path at the very end
end

%% Local Helper function to calculate solution metrics
function [numRoutes, totalDistance, avgCustomersPerRoute] = calculateSolutionMetrics(solution, locations, numSelectedHubs, ~) % utils argument marked as unused
    numRoutes = 0;
    totalDistance = 0;
    totalCustomersServedOnRoutes = 0;
    
    if isempty(solution) || ~iscell(solution)
        avgCustomersPerRoute = 0;
        return;
    end

    for r = 1:length(solution)
        route = solution{r};
        if isempty(route) || ~isnumeric(route) || length(route) <= 2 
            continue;
        end
        if any(route < 1) || any(route > size(locations,1)) % Check bounds
            fprintf('Warning (calculateSolutionMetrics): Route %d contains invalid location indices. Skipping this route.\n',r);
            continue;
        end
        if route(1) > numSelectedHubs || route(end) > numSelectedHubs || route(1) ~= route(end)
             fprintf('Warning (calculateSolutionMetrics): Route %d has invalid hub structure. Skipping this route.\n',r);
            continue;
        end

        numRoutes = numRoutes + 1;
        routeDist = 0;
        customersOnThisRoute = 0;
        for leg = 1:(length(route) - 1)
            loc1Idx = route(leg);
            loc2Idx = route(leg+1);
            routeDist = routeDist + common_utilities.calculate_Haversine_Distance(locations(loc1Idx,1), locations(loc1Idx,2), locations(loc2Idx,1), locations(loc2Idx,2)); %
            if loc2Idx > numSelectedHubs 
                customersOnThisRoute = customersOnThisRoute + 1;
            end
        end
        totalDistance = totalDistance + routeDist;
        totalCustomersServedOnRoutes = totalCustomersServedOnRoutes + customersOnThisRoute;
    end
    
    if numRoutes > 0
        avgCustomersPerRoute = totalCustomersServedOnRoutes / numRoutes;
    else
        avgCustomersPerRoute = 0;
    end
end