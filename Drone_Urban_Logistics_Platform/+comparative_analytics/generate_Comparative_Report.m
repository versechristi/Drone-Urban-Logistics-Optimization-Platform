% File: Drone_Urban_Logistics_Platform/+comparative_analytics/generate_Comparative_Report.m
function generate_Comparative_Report(sa_finalResults, aco_finalResults, sa_params, aco_params, scenario_params, drone_params, reportFilePath)
% Generates a text report comparing the results and parameters of SA and ACO.
%
% INPUTS:
%   sa_finalResults (struct): SA's final metrics.
%   aco_finalResults (struct): ACO's final metrics.
%   sa_params (struct): Parameters used for the SA run.
%   aco_params (struct): Parameters used for the ACO run.
%   scenario_params (struct): Scenario parameters.
%   drone_params (struct): Drone parameters.
%   reportFilePath (string): Full path to save the text report.

    fprintf('Generating comparative report to: %s\n', reportFilePath);

    try
        fid = fopen(reportFilePath, 'w');
        if fid == -1
            error('Cannot open file %s for writing.', reportFilePath);
        end

        fprintf(fid, '============================================================\n');
        fprintf(fid, '      COMPARATIVE ANALYSIS REPORT: SA vs. ACO for MDVRP      \n');
        fprintf(fid, '============================================================\n');
        fprintf(fid, 'Date Generated: %s\n\n', datestr(now, 'yyyy-mm-dd HH:MM:SS'));

        % --- Scenario Parameters ---
        fprintf(fid, '------------------------------------------------------------\n');
        fprintf(fid, 'I. SCENARIO & DRONE PARAMETERS\n');
        fprintf(fid, '------------------------------------------------------------\n');
        fprintf(fid, 'Center Location: Lat %.4f, Lon %.4f\n', scenario_params.CenterLatitude, scenario_params.CenterLongitude);
        fprintf(fid, 'Map Radius: %.1f km\n', scenario_params.MapRadiusKm);
        fprintf(fid, 'Number of Customers: %d\n', scenario_params.NumCustomers);
        fprintf(fid, 'Number of Candidate Depots: %d\n', scenario_params.NumCandidateDepots);
        fprintf(fid, 'Number of Hubs Selected: %d\n', scenario_params.NumHubsToSelect);
        fprintf(fid, '\n');
        fprintf(fid, 'Drone Payload Capacity: %.1f units\n', drone_params.PayloadCapacity);
        fprintf(fid, 'Drone Max Range: %.1f km\n', drone_params.MaxRangeKm);
        fprintf(fid, 'Drone Unit Cost: %.2f /km\n', drone_params.UnitCostPerKm);
        fprintf(fid, '\n');

        % --- Simulated Annealing (SA) ---
        fprintf(fid, '------------------------------------------------------------\n');
        fprintf(fid, 'II. SIMULATED ANNEALING (SA) RESULTS\n');
        fprintf(fid, '------------------------------------------------------------\n');
        fprintf(fid, 'Parameters:\n');
        fprintf(fid, '  Initial Temperature: %.2f\n', sa_params.InitialTemp);
        fprintf(fid, '  Final Temperature: %.2f\n', sa_params.FinalTemp);
        fprintf(fid, '  Cooling Rate (Alpha): %.4f\n', sa_params.Alpha);
        fprintf(fid, '  Iterations per Temperature: %d\n', sa_params.MaxIterPerTemp);
        fprintf(fid, '\nPerformance:\n');
        if isfield(sa_finalResults, 'Cost'), fprintf(fid, '  Final Best Cost: %.2f\n', sa_finalResults.Cost); end
        if isfield(sa_finalResults, 'ComputationTime'), fprintf(fid, '  Computation Time: %.2f seconds\n', sa_finalResults.ComputationTime); end
        if isfield(sa_finalResults, 'NumRoutes'), fprintf(fid, '  Number of Routes: %d\n', sa_finalResults.NumRoutes); end
        if isfield(sa_finalResults, 'TotalDistance'), fprintf(fid, '  Total Distance Traveled: %.2f km\n', sa_finalResults.TotalDistance); end
        if isfield(sa_finalResults, 'AvgCustomersPerRoute'), fprintf(fid, '  Avg. Customers per Route: %.2f\n', sa_finalResults.AvgCustomersPerRoute); end
        fprintf(fid, '\n');

        % --- Ant Colony Optimization (ACO) ---
        fprintf(fid, '------------------------------------------------------------\n');
        fprintf(fid, 'III. ANT COLONY OPTIMIZATION (ACO) RESULTS\n');
        fprintf(fid, '------------------------------------------------------------\n');
        fprintf(fid, 'Parameters:\n');
        fprintf(fid, '  Number of Ants: %d\n', aco_params.NumAnts);
        fprintf(fid, '  Max Iterations: %d\n', aco_params.MaxIterations);
        fprintf(fid, '  Pheromone Evaporation (rho): %.4f\n', aco_params.Rho_Evaporation);
        fprintf(fid, '  Pheromone Importance (alpha_aco): %.2f\n', aco_params.Alpha_PheromoneImportance);
        fprintf(fid, '  Heuristic Importance (beta_aco): %.2f\n', aco_params.Beta_HeuristicImportance);
        fprintf(fid, '  Initial Pheromone (tau0): %.4f\n', aco_params.Tau0_InitialPheromone);
        if isfield(aco_params, 'Q_PheromoneFactor'), fprintf(fid, '  Pheromone Factor (Q): %.2f\n', aco_params.Q_PheromoneFactor); end
        fprintf(fid, '\nPerformance:\n');
        if isfield(aco_finalResults, 'Cost'), fprintf(fid, '  Final Best Cost: %.2f\n', aco_finalResults.Cost); end
        if isfield(aco_finalResults, 'ComputationTime'), fprintf(fid, '  Computation Time: %.2f seconds\n', aco_finalResults.ComputationTime); end
        if isfield(aco_finalResults, 'NumRoutes'), fprintf(fid, '  Number of Routes: %d\n', aco_finalResults.NumRoutes); end
        if isfield(aco_finalResults, 'TotalDistance'), fprintf(fid, '  Total Distance Traveled: %.2f km\n', aco_finalResults.TotalDistance); end
        if isfield(aco_finalResults, 'AvgCustomersPerRoute'), fprintf(fid, '  Avg. Customers per Route: %.2f\n', aco_finalResults.AvgCustomersPerRoute); end
        fprintf(fid, '\n');
        
        % --- Brief Comparison Summary ---
        fprintf(fid, '------------------------------------------------------------\n');
        fprintf(fid, 'IV. QUICK COMPARISON\n');
        fprintf(fid, '------------------------------------------------------------\n');
        if isfield(sa_finalResults, 'Cost') && isfield(aco_finalResults, 'Cost')
            fprintf(fid, 'Lowest Cost: ');
            if sa_finalResults.Cost < aco_finalResults.Cost
                fprintf(fid, 'SA (%.2f) vs ACO (%.2f)\n', sa_finalResults.Cost, aco_finalResults.Cost);
            elseif aco_finalResults.Cost < sa_finalResults.Cost
                fprintf(fid, 'ACO (%.2f) vs SA (%.2f)\n', aco_finalResults.Cost, sa_finalResults.Cost);
            else
                fprintf(fid, 'Both SA and ACO achieved same cost (%.2f)\n', sa_finalResults.Cost);
            end
        end
         if isfield(sa_finalResults, 'ComputationTime') && isfield(aco_finalResults, 'ComputationTime')
            fprintf(fid, 'Faster Computation: ');
            if sa_finalResults.ComputationTime < aco_finalResults.ComputationTime
                fprintf(fid, 'SA (%.2fs) vs ACO (%.2fs)\n', sa_finalResults.ComputationTime, aco_finalResults.ComputationTime);
            elseif aco_finalResults.ComputationTime < sa_finalResults.ComputationTime
                fprintf(fid, 'ACO (%.2fs) vs SA (%.2fs)\n', aco_finalResults.ComputationTime, sa_finalResults.ComputationTime);
            else
                fprintf(fid, 'Both SA and ACO had similar computation time (%.2fs)\n', sa_finalResults.ComputationTime);
            end
        end
        fprintf(fid, '============================================================\n');
        fprintf(fid, '                        END OF REPORT                       \n');
        fprintf(fid, '============================================================\n');

        fclose(fid);
        fprintf('Comparative report successfully saved.\n');

    catch ME_report
        if fid ~= -1, fclose(fid); end % Ensure file is closed on error
        warning('generate_Comparative_Report:FileError', ...
                'Error generating comparative report: %s', ME_report.message);
    end
end