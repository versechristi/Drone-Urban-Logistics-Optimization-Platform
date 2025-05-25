% File: Drone_Urban_Logistics_Platform/+hub_selection_layout/optimize_Hub_Locations.m
function selectedHubs = optimize_Hub_Locations(customers, candidateDepots, numHubsToSelect, ~) % utils argument marked as unused
% Selects optimal hub locations from a list of candidate depots.
% Strategy:
% 1. Perform K-means clustering on customer locations to find 'numHubsToSelect' centroids.
% 2. For each customer cluster centroid, greedily assign the closest available candidate depot.
%
% INPUTS:
%   customers (struct array): Customer data (requires .Latitude, .Longitude fields).
%   candidateDepots (struct array): Candidate depot data (requires .ID, .Latitude, .Longitude fields).
%   numHubsToSelect (integer): The number of hubs to select.
%   ~ (any, optional): Formerly utils struct, now unused.
%
% OUTPUTS:
%   selectedHubs (struct array): An array of structs for the selected hubs,
%                                 containing .ID, .Latitude, .Longitude, and
%                                 optionally .AssignedCustomerCentroidLat, .AssignedCustomerCentroidLon.

    fprintf('Optimizing %d hub locations from %d candidates for %d customers...\n', ...
            numHubsToSelect, length(candidateDepots), length(customers));

    if numHubsToSelect == 0
        selectedHubs = struct('ID', {}, 'Latitude', {}, 'Longitude', {}, ...
                              'AssignedCustomerCentroidLat', {}, 'AssignedCustomerCentroidLon', {});
        fprintf('No hubs to select.\n');
        return;
    end

    if isempty(candidateDepots)
        error('optimize_Hub_Locations:NoCandidateDepots', 'Candidate depots list is empty.');
    end
    
    if numHubsToSelect > length(candidateDepots)
        warning('optimize_Hub_Locations:InsufficientCandidates', ...
                'Number of hubs to select (%d) exceeds available unique candidate depots (%d). Selecting all candidates.', ...
                numHubsToSelect, length(candidateDepots));
        selectedHubs = candidateDepots;
        % Add dummy centroid assignments if needed for consistent struct
        for i = 1:length(selectedHubs)
            selectedHubs(i).AssignedCustomerCentroidLat = NaN;
            selectedHubs(i).AssignedCustomerCentroidLon = NaN;
        end
        return;
    end

    if isempty(customers)
        error('optimize_Hub_Locations:NoCustomers', 'Customer data is empty. Cannot perform K-means.');
    end

    customerCoords = [vertcat(customers.Latitude), vertcat(customers.Longitude)];

    % 1. Perform K-means clustering on customer locations
    % Suppress iteration display for kmeans for cleaner output
    opts = statset('Display','off'); 
    try
        [~, customerClusterCentroids] = kmeans(customerCoords, numHubsToSelect, 'Replicates', 5, 'Options', opts);
    catch ME
        if strcmp(ME.identifier, 'stats:kmeans:TooFewUniquePoints') || size(customerCoords,1) < numHubsToSelect
             warning('optimize_Hub_Locations:KmeansError', ...
                'K-means failed likely due to too few unique customer points (%d) for K=%d. Using first K candidate depots as a fallback.', size(unique(customerCoords,'rows'),1) , numHubsToSelect);
            selectedHubsIndices = 1:numHubsToSelect;
            selectedHubs = candidateDepots(selectedHubsIndices);
            for i = 1:length(selectedHubs)
                selectedHubs(i).AssignedCustomerCentroidLat = NaN;
                selectedHubs(i).AssignedCustomerCentroidLon = NaN;
            end
            return;
        else
            rethrow(ME);
        end
    end


    candidateDepotCoords = [vertcat(candidateDepots.Latitude), vertcat(candidateDepots.Longitude)];
    numActualCandidateDepots = size(candidateDepotCoords, 1);

    selectedHubIndices = zeros(1, numHubsToSelect);
    assignedCentroidCoords = zeros(numHubsToSelect, 2);
    availableCandidateIndices = 1:numActualCandidateDepots;

    % 2. Greedily assign the closest available candidate depot to each customer cluster centroid
    for i = 1:numHubsToSelect
        centroidLat = customerClusterCentroids(i, 1);
        centroidLon = customerClusterCentroids(i, 2);
        
        minDist = inf;
        bestCandidateIdxInAvailable = -1; % Index within the 'availableCandidateIndices' array
        
        if isempty(availableCandidateIndices)
            error('optimize_Hub_Locations:RanOutOfCandidates', ...
                  'Ran out of available candidate depots to assign to customer centroids. This should not happen if numHubsToSelect <= numActualCandidateDepots.');
        end

        for j = 1:length(availableCandidateIndices)
            currentCandidateOriginalIdx = availableCandidateIndices(j);
            depotLat = candidateDepotCoords(currentCandidateOriginalIdx, 1);
            depotLon = candidateDepotCoords(currentCandidateOriginalIdx, 2);
            
            % --- MODIFICATION: Call Haversine distance directly from common_utilities ---
            dist = common_utilities.calculate_Haversine_Distance(centroidLat, centroidLon, depotLat, depotLon); %
            
            if dist < minDist
                minDist = dist;
                bestCandidateIdxInAvailable = j;
            end
        end
        
        % Assign the best found candidate for this centroid
        selectedOriginalDepotIndex = availableCandidateIndices(bestCandidateIdxInAvailable);
        selectedHubIndices(i) = selectedOriginalDepotIndex;
        assignedCentroidCoords(i,:) = [centroidLat, centroidLon];
        
        % Remove the selected candidate from the available list
        availableCandidateIndices(bestCandidateIdxInAvailable) = []; 
    end

    % Ensure uniqueness (though the above loop should handle it)
    selectedHubIndices = unique(selectedHubIndices, 'stable');
    if length(selectedHubIndices) < numHubsToSelect
        warning('optimize_Hub_Locations:FewerHubsSelected', ...
                'Could only select %d unique hubs due to proximity or few candidates, though %d were requested. This might indicate an issue in the selection logic or data.', ...
                length(selectedHubIndices), numHubsToSelect);
        % If fewer are selected, we might need to pad or handle this.
        % For now, we proceed with the uniquely selected ones.
        % Or, we could try to fill the remaining slots greedily from remaining centroids and candidates.
        % However, the current loop structure aims to pick one unique depot per centroid.
    end
    
    selectedHubs = candidateDepots(selectedHubIndices);

    % Add assigned customer centroid information to the selected hubs
    % This requires careful matching if selectedHubIndices was modified by unique()
    % The loop structure above should assign one hub per centroid, so selectedHubIndices will have numHubsToSelect elements.
    for i = 1:length(selectedHubs)
        % Find which centroid this hub was originally assigned to.
        % The order of selectedHubs is based on the order in selectedHubIndices,
        % which corresponds to the iteration i of the centroid loop.
        originalCentroidIndex = find(selectedHubIndices == selectedHubs(i).ID,1); % This assumes depot IDs are 1-based and match their original index.
                                                                            % If IDs are not sequential/index-based, this needs adjustment.
                                                                            % A safer way if IDs are arbitrary:
        idxInSelectedHubIndices = find(selectedHubIndices == candidateDepots(selectedHubs(i).ID).ID, 1); % if selectedHubs(i).ID is the original index

        % Simpler: since selectedHubIndices are already in order of centroid assignment loop 1 to K
        % and selectedHubs = candidateDepots(selectedHubIndices) preserves that order.
        selectedHubs(i).AssignedCustomerCentroidLat = assignedCentroidCoords(i,1);
        selectedHubs(i).AssignedCustomerCentroidLon = assignedCentroidCoords(i,2);
    end

    fprintf('Hub location optimization complete. Selected %d hubs.\n', length(selectedHubs));
end