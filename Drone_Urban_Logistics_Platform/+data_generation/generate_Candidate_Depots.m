% File: Drone_Urban_Logistics_Platform/+data_generation/generate_Candidate_Depots.m
function candidateDepots = generate_Candidate_Depots(scenarioParams)
% Generates candidate depot locations.
%
% INPUTS:
%   scenarioParams (struct): A structure containing scenario parameters, typically:
%       .CenterLatitude     (double) - Latitude of the simulation center.
%       .CenterLongitude    (double) - Longitude of the simulation center.
%       .MapRadiusKm        (double) - Radius in km around the center for generation.
%                                      (Could be same or different from customer radius)
%       .NumCandidateDepots (integer)- Number of candidate depots to generate.
%
% OUTPUTS:
%   candidateDepots (struct array): An array of structs, where each struct has:
%       .ID                 (integer)- Unique candidate depot ID.
%       .Latitude           (double) - Depot's latitude.
%       .Longitude          (double) - Depot's longitude.

    fprintf('Generating %d candidate depot locations...\n', scenarioParams.NumCandidateDepots);

    if scenarioParams.NumCandidateDepots <= 0
        candidateDepots = struct('ID', {}, 'Latitude', {}, 'Longitude', {});
        fprintf('No candidate depots to generate.\n');
        return;
    end

    % Approximate conversion (same as for customers)
    deltaLat_deg = scenarioParams.MapRadiusKm / 111.0;
    deltaLon_deg = scenarioParams.MapRadiusKm / (111.0 * cosd(scenarioParams.CenterLatitude));

    % Generate random latitudes and longitudes
    randLats = scenarioParams.CenterLatitude + deltaLat_deg * (2*rand(scenarioParams.NumCandidateDepots, 1) - 1);
    randLons = scenarioParams.CenterLongitude + deltaLon_deg * (2*rand(scenarioParams.NumCandidateDepots, 1) - 1);

    candidateDepots = struct('ID', num2cell(1:scenarioParams.NumCandidateDepots)', ...
                             'Latitude', num2cell(randLats), ...
                             'Longitude', num2cell(randLons));

    fprintf('Candidate depot locations generation complete.\n');
end