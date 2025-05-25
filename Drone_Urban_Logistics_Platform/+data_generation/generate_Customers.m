% File: Drone_Urban_Logistics_Platform/+data_generation/generate_Customers.m
function customers = generate_Customers(scenarioParams)
% Generates customer data including locations and demands.
%
% INPUTS:
%   scenarioParams (struct): A structure containing scenario parameters, typically:
%       .CenterLatitude     (double) - Latitude of the simulation center.
%       .CenterLongitude    (double) - Longitude of the simulation center.
%       .MapRadiusKm        (double) - Radius in km around the center for generation.
%       .NumCustomers       (integer)- Number of customers to generate.
%
% OUTPUTS:
%   customers (struct array): An array of structs, where each struct has:
%       .ID                 (integer)- Unique customer ID.
%       .Latitude           (double) - Customer's latitude.
%       .Longitude          (double) - Customer's longitude.
%       .Demand             (integer)- Customer's demand (e.g., number of packages).

    fprintf('Generating %d customer locations and demands...\n', scenarioParams.NumCustomers);

    % Approximate conversion: 1 degree of latitude ~ 111 km
    % 1 degree of longitude ~ 111 km * cos(latitude)
    deltaLat_deg = scenarioParams.MapRadiusKm / 111.0;
    deltaLon_deg = scenarioParams.MapRadiusKm / (111.0 * cosd(scenarioParams.CenterLatitude));

    % Generate random latitudes and longitudes within the bounding box
    % defined by CenterLat +/- deltaLat_deg and CenterLon +/- deltaLon_deg.
    % Using (2*rand - 1) creates values between -1 and 1.
    randLats = scenarioParams.CenterLatitude + deltaLat_deg * (2*rand(scenarioParams.NumCustomers, 1) - 1);
    randLons = scenarioParams.CenterLongitude + deltaLon_deg * (2*rand(scenarioParams.NumCustomers, 1) - 1);

    % Define demand characteristics (can be made more complex or configurable)
    minDemand = 1;
    maxDemand = 5; % e.g., 1 to 5 packages/units
    randDemands = randi([minDemand, maxDemand], scenarioParams.NumCustomers, 1);

    customers = struct('ID', num2cell(1:scenarioParams.NumCustomers)', ...
                       'Latitude', num2cell(randLats), ...
                       'Longitude', num2cell(randLons), ...
                       'Demand', num2cell(randDemands));

    fprintf('Customer data generation complete.\n');
end