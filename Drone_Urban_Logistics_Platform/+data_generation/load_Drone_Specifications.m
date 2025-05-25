% File: Drone_Urban_Logistics_Platform/+data_generation/load_Drone_Specifications.m
function droneSpecs = load_Drone_Specifications(droneParamsFromUI)
% Loads or formalizes drone specifications.
% For now, it primarily structures the parameters received from the UI.
%
% INPUTS:
%   droneParamsFromUI (struct): A structure containing drone parameters from the UI, typically:
%       .PayloadCapacity (double) - Max payload in units (e.g., packages, kg).
%       .MaxRangeKm      (double) - Max flight range in km.
%       .UnitCostPerKm   (double) - Cost per kilometer.
%
% OUTPUTS:
%   droneSpecs (struct): A structured representation of drone specifications.
%       .PayloadCapacity (double)
%       .MaxRangeKm      (double)
%       .UnitCostPerKm   (double)
%       (Can be extended with other parameters like speed, battery life, fixed cost per trip etc.)

    fprintf('Loading drone specifications...\n');

    if ~isstruct(droneParamsFromUI) || ...
       ~isfield(droneParamsFromUI, 'PayloadCapacity') || ...
       ~isfield(droneParamsFromUI, 'MaxRangeKm') || ...
       ~isfield(droneParamsFromUI, 'UnitCostPerKm')
        error('load_Drone_Specifications:InvalidInput', ...
              'Input droneParamsFromUI is missing required fields (PayloadCapacity, MaxRangeKm, UnitCostPerKm).');
    end

    droneSpecs = struct();
    droneSpecs.PayloadCapacity = droneParamsFromUI.PayloadCapacity;
    droneSpecs.MaxRangeKm = droneParamsFromUI.MaxRangeKm;
    droneSpecs.UnitCostPerKm = droneParamsFromUI.UnitCostPerKm;
    
    % Example for future extension:
    % droneSpecs.AverageSpeedKmph = 40; % Default or from a more detailed config
    % droneSpecs.BatteryChargingTimeHours = 1.5;

    fprintf('Drone specifications loaded: Payload=%.1f, Range=%.1fkm, Cost/km=%.2f\n', ...
            droneSpecs.PayloadCapacity, droneSpecs.MaxRangeKm, droneSpecs.UnitCostPerKm);
end