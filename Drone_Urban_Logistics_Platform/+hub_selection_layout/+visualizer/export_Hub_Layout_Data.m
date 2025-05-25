% File: Drone_Urban_Logistics_Platform/+hub_selection_layout/+visualizer/export_Hub_Layout_Data.m
function export_Hub_Layout_Data(selectedHubs, filePathWithoutExtension)
% Exports selected hub data to CSV and MAT files.
%
% INPUTS:
%   selectedHubs (struct array): The selected hubs (.ID, .Latitude, .Longitude, 
%                                .AssignedCustomerCentroidLat, .AssignedCustomerCentroidLon - optional).
%   filePathWithoutExtension (string): The base file path (e.g., 'results_output/exp1/hub_layout_results/selected_hubs_data').

    fprintf('Exporting hub layout data...\n'); % MODIFIED: Changed from solve_ACO_VRP.m to fprintf

    if isempty(selectedHubs)
        fprintf('No selected hubs to export.\n');
        return;
    end

    % Create table for CSV export
    try
        % Check for optional fields for a more complete table
        hasCentroidInfo = isfield(selectedHubs, 'AssignedCustomerCentroidLat') && ...
                          isfield(selectedHubs, 'AssignedCustomerCentroidLon');
        
        numSelected = length(selectedHubs);
        IDs = zeros(numSelected, 1);
        Lats = zeros(numSelected, 1);
        Lons = zeros(numSelected, 1);
        CentLats = nan(numSelected, 1); % Initialize with NaN
        CentLons = nan(numSelected, 1); % Initialize with NaN

        for i = 1:numSelected
            IDs(i) = selectedHubs(i).ID;
            Lats(i) = selectedHubs(i).Latitude;
            Lons(i) = selectedHubs(i).Longitude;
            if hasCentroidInfo
                if ~isempty(selectedHubs(i).AssignedCustomerCentroidLat)
                    CentLats(i) = selectedHubs(i).AssignedCustomerCentroidLat;
                end
                if ~isempty(selectedHubs(i).AssignedCustomerCentroidLon)
                    CentLons(i) = selectedHubs(i).AssignedCustomerCentroidLon;
                end
            end
        end
        
        if hasCentroidInfo
            T = table(IDs, Lats, Lons, CentLats, CentLons, ...
                'VariableNames', {'HubID', 'Latitude', 'Longitude', 'AssignedCentroidLat', 'AssignedCentroidLon'});
        else
            T = table(IDs, Lats, Lons, ...
                'VariableNames', {'HubID', 'Latitude', 'Longitude'});
        end
        
        % Export to CSV
        csvFilePath = [filePathWithoutExtension, '.csv'];
        writetable(T, csvFilePath);
        fprintf('Hub data exported to CSV: %s\n', csvFilePath);

    catch ME_csv
        warning('export_Hub_Layout_Data:CSVError', ...
            'Could not export hub data to CSV: %s', ME_csv.message);
    end

    % Export to MAT file (saves the original struct array)
    try
        matFilePath = [filePathWithoutExtension, '.mat'];
        save(matFilePath, 'selectedHubs');
        fprintf('Hub data exported to MAT: %s\n', matFilePath);
    catch ME_mat
         warning('export_Hub_Layout_Data:MATError', ...
            'Could not export hub data to MAT: %s', ME_mat.message);
    end
end