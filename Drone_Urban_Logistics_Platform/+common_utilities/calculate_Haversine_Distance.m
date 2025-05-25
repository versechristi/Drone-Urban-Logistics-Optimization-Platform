% File: Drone_Urban_Logistics_Platform/+common_utilities/calculate_Haversine_Distance.m
function distance_km = calculate_Haversine_Distance(lat1_deg, lon1_deg, lat2_deg, lon2_deg)
% Calculates the Haversine distance between two points on Earth.
%
% INPUTS:
%   lat1_deg (double): Latitude of point 1 in degrees.
%   lon1_deg (double): Longitude of point 1 in degrees.
%   lat2_deg (double): Latitude of point 2 in degrees.
%   lon2_deg (double): Longitude of point 2 in degrees.
%
% OUTPUTS:
%   distance_km (double): Distance between the two points in kilometers.

    R = 6371; % Earth's mean radius in kilometers

    % Convert degrees to radians
    lat1_rad = deg2rad(lat1_deg);
    lon1_rad = deg2rad(lon1_deg);
    lat2_rad = deg2rad(lat2_deg);
    lon2_rad = deg2rad(lon2_deg);

    % Haversine formula
    deltaLat = lat2_rad - lat1_rad;
    deltaLon = lon2_rad - lon1_rad;

    a = sin(deltaLat/2)^2 + cos(lat1_rad) * cos(lat2_rad) * sin(deltaLon/2)^2;
    c = 2 * atan2(sqrt(a), sqrt(1-a));

    distance_km = R * c;
end