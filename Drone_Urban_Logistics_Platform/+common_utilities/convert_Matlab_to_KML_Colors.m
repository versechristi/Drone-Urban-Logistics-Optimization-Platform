% File: Drone_Urban_Logistics_Platform/+common_utilities/convert_Matlab_to_KML_Colors.m
function kmlColorStrings = convert_Matlab_to_KML_Colors(matlabColors, alphaValue)
% Converts MATLAB RGB colors [0-1] to KML color strings (AABBGGRR hex).
%
% INPUTS:
%   matlabColors (Nx3 matrix): MATLAB RGB colors, where N is the number of colors.
%                             Each row is [R, G, B] with values between 0 and 1.
%   alphaValue (double, optional): Alpha transparency value (0 to 1). Default is 1 (opaque).
%
% OUTPUTS:
%   kmlColorStrings (cell array or char array): KML color strings. If N=1, returns char array.

    if nargin < 2
        alphaValue = 1.0; % Default to fully opaque
    end
    
    numColors = size(matlabColors, 1);
    kmlColorStrings = cell(numColors, 1);
    
    % Ensure alpha is within [0,1] and convert to hex (AA)
    alphaValue = max(0, min(1, alphaValue));
    alphaHex = dec2hex(round(alphaValue * 255), 2);

    for i = 1:numColors
        r = matlabColors(i, 1);
        g = matlabColors(i, 2);
        b = matlabColors(i, 3);

        % Ensure RGB values are within [0,1]
        r = max(0, min(1, r));
        g = max(0, min(1, g));
        b = max(0, min(1, b));

        rHex = dec2hex(round(r * 255), 2); % RR
        gHex = dec2hex(round(g * 255), 2); % GG
        bHex = dec2hex(round(b * 255), 2); % BB

        kmlColorStrings{i} = [alphaHex, bHex, gHex, rHex]; % KML format is AABBGGRR
    end

    if numColors == 1
        kmlColorStrings = kmlColorStrings{1}; % Return as char array if only one color
    end
end