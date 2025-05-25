% File: Drone_Urban_Logistics_Platform/+common_utilities/save_Figure_Properly.m
function save_Figure_Properly(figHandle, filePathWithoutExtension, formats, resolutionDPI)
% Saves the given figure handle to specified formats with good quality.
%
% INPUTS:
%   figHandle (matlab.ui.Figure): Handle of the figure to save.
%   filePathWithoutExtension (string): Base path and filename without extension
%                                     (e.g., 'results/myplot').
%   formats (cell array of strings, optional): Formats to save in, e.g., {'png', 'fig', 'eps'}.
%                                              Defaults to {'png', 'fig'}.
%   resolutionDPI (integer, optional): Resolution in DPI for raster formats (like PNG).
%                                       Defaults to 300.

    if nargin < 3 || isempty(formats)
        formats = {'png', 'fig'}; % Default formats
    end
    if nargin < 4 || isempty(resolutionDPI)
        resolutionDPI = 300; % Default resolution
    end

    % Initial check of the figure handle
    if isempty(figHandle) || ~ishandle(figHandle) || ~strcmp(get(figHandle, 'Type'), 'figure')
        warning('save_Figure_Properly:InvalidHandleInput', 'Input handle is not a valid figure handle or is empty. Skipping save for: %s', filePathWithoutExtension);
        return;
    end
    
    originalVisibility = get(figHandle, 'Visible');
    set(figHandle, 'Visible', 'on'); % Make it visible to ensure proper rendering
    drawnow expose; % Use 'expose' for more thorough rendering update
    
    % Check handle validity after drawnow (it might have been closed by a callback triggered by drawnow)
    if ~ishandle(figHandle)
        warning('save_Figure_Properly:HandleInvalidAfterDrawnow', 'Figure handle became invalid after drawnow. Skipping save for: %s', filePathWithoutExtension);
        % Cannot restore originalVisibility if handle is invalid and was different
        return;
    end

    originalPaperPositionMode = get(figHandle, 'PaperPositionMode');
    set(figHandle, 'PaperPositionMode', 'auto'); % Ensures saved aspect ratio matches screen

    for i = 1:length(formats)
        format = lower(formats{i});
        fullFilePath = [filePathWithoutExtension, '.', format];
        
        % Check handle validity at the start of each format saving attempt
        if ~ishandle(figHandle)
            warning('save_Figure_Properly:HandleInvalidMidLoop', 'Figure handle became invalid before saving %s format for: %s. Aborting further saves.', format, filePathWithoutExtension);
            % Try to restore original PaperPositionMode if possible (though if handle is bad, this might also fail)
            % No, if handle is bad, don't try to set properties.
            return; % Exit the function, no more formats will be saved
        end

        try
            currentFigHandleState = figHandle; % Store current handle value for comparison
            switch format
                case 'png'
                    print(figHandle, fullFilePath, '-dpng', ['-r', num2str(resolutionDPI)]);
                case 'jpg'
                    print(figHandle, fullFilePath, '-djpeg', ['-r', num2str(resolutionDPI)]);
                case 'tif'
                    print(figHandle, fullFilePath, '-dtiff', ['-r', num2str(resolutionDPI)]);
                case 'eps'
                    print(figHandle, fullFilePath, '-depsc'); 
                case 'pdf'
                    % Ensure figure content is rendered before PDF export, especially for complex plots
                    % Might need '-painters' for vector graphics if default renderer causes issues
                    print(figHandle, fullFilePath, '-dpdf', '-fillpage', '-bestfit'); 
                case 'fig'
                    if ~ishandle(figHandle) % Check again just before savefig
                        warning('save_Figure_Properly:HandleInvalidBeforeSaveFig', 'Figure handle invalid just before calling savefig for: %s', fullFilePath);
                    else
                        savefig(figHandle, fullFilePath);
                    end
                otherwise
                    warning('save_Figure_Properly:UnknownFormat', 'Unsupported format: %s for %s. Skipping.', format, filePathWithoutExtension);
                    continue; % Skip to next format
            end
            
            % Check handle validity immediately after save operation
            if ~ishandle(figHandle) || (isobject(figHandle) && ~isvalid(figHandle))
                % The (isobject && ~isvalid) is for newer graphics objects that might not be caught by ishandle alone
                fprintf('WARNING: Figure handle (original value: %.16g) became invalid immediately after saving to %s format for: %s.\n', ...
                        double(currentFigHandleState), format, filePathWithoutExtension); % Log original handle value
                 % If handle becomes invalid, stop trying to save other formats.
                 % Cannot restore properties reliably.
                return; 
            else
                fprintf('Figure saved to: %s\n', fullFilePath);
            end
        catch ME
            warning('save_Figure_Properly:SaveError', 'Could not save figure to %s format for "%s": %s', format, filePathWithoutExtension, ME.message);
            fprintf('Stack trace for save error:\n');
            disp(ME.getReport('extended', 'hyperlinks', 'off'));
            
            if ~ishandle(figHandle) || (isobject(figHandle) && ~isvalid(figHandle))
                 fprintf('WARNING: Figure handle is also invalid after the FAILED save attempt for %s format. Aborting further saves.\n', format);
                 % Cannot restore properties reliably.
                 return; % Exit the function
            end
        end
    end
    
    % Restore original properties only if handle is still valid at the very end
    if ishandle(figHandle)
        set(figHandle, 'PaperPositionMode', originalPaperPositionMode);
        if ~strcmp(originalVisibility, 'on') 
            % set(figHandle, 'Visible', originalVisibility); % Decided against auto-hiding in original
        end
    else
        warning('save_Figure_Properly:HandleInvalidAtEnd', 'Figure handle is invalid at the end of save_Figure_Properly for: %s. Original properties not restored.', filePathWithoutExtension);
    end
end