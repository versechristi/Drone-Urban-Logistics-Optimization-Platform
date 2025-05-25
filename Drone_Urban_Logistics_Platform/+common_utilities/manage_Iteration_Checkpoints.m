% File: Drone_Urban_Logistics_Platform/+common_utilities/manage_Iteration_Checkpoints.m
function checkpoints = manage_Iteration_Checkpoints(totalAlgorithmIterations, initialFixedCheckpoints, numIntermediateDynamicPoints)
% Calculates a list of iteration numbers for saving intermediate results.
% Includes initial fixed points, dynamically calculated points (e.g., 1/3, 2/3),
% and the final iteration.
%
% INPUTS:
%   totalAlgorithmIterations (integer): Total number of iterations the algorithm will run.
%   initialFixedCheckpoints (vector, optional): A vector of early iteration numbers to always include.
%                                               Defaults to [1, 5] if totalIterations allow.
%   numIntermediateDynamicPoints (integer, optional): Number of dynamic points to spread out
%                                                    (e.g., 2 for 1/3 and 2/3). Defaults to 2.
%
% OUTPUTS:
%   checkpoints (vector): Sorted, unique vector of iteration numbers for checkpoints.

    if nargin < 2 || isempty(initialFixedCheckpoints)
        initialFixedCheckpoints = [1, 5];
    end
    if nargin < 3 || isempty(numIntermediateDynamicPoints)
        numIntermediateDynamicPoints = 2; % e.g., for 1/3 and 2/3
    end

    checkpoints = [];

    % Add initial fixed checkpoints, ensuring they are within bounds
    for cp = initialFixedCheckpoints
        if cp > 0 && cp < totalAlgorithmIterations
            checkpoints(end+1) = cp;
        end
    end

    % Add dynamically calculated intermediate points
    if numIntermediateDynamicPoints > 0 && totalAlgorithmIterations > max([10, max(initialFixedCheckpoints)]) % Only if enough iterations
        for i = 1:numIntermediateDynamicPoints
            dynamic_cp = floor((i / (numIntermediateDynamicPoints + 1)) * totalAlgorithmIterations);
            if dynamic_cp > 0 && dynamic_cp < totalAlgorithmIterations
                 checkpoints(end+1) = dynamic_cp;
            end
        end
    end
    
    % Always include the first and last iteration if meaningful
    if totalAlgorithmIterations > 0
        checkpoints(end+1) = 1; % Ensure first iteration is often a checkpoint
        checkpoints(end+1) = totalAlgorithmIterations; % Always include the final iteration
    end
    
    % Ensure checkpoints are unique and sorted, and within bounds
    checkpoints = unique(checkpoints);
    checkpoints = checkpoints(checkpoints > 0 & checkpoints <= totalAlgorithmIterations);
    
    if isempty(checkpoints) && totalAlgorithmIterations > 0
        checkpoints = totalAlgorithmIterations; % At least the last one
    elseif isempty(checkpoints) && totalAlgorithmIterations == 0
        checkpoints = [];
    end
    
    fprintf('Managed checkpoints for %d total iterations: %s\n', totalAlgorithmIterations, mat2str(checkpoints));
end