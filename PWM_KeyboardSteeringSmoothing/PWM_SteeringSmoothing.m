function PWM_SteeringSmooth()
% Prototype of smoothing steering on keyboard
% with using Pulse-width modulation (PWM)
%
% ------
% Author: Vitaly Lyashchenko
% e-mail: scxv86@gmail.com
% Created: 2016-06-05,    using Matlab 9.0.0.341360 (R2016a)

    isProcessing = true;
    isKeyUp = false;

    function ClearAll()
        close all;            % close all figures
        clear all;            % clear all workspace variables
        clc;                  % clear the command line
        fclose('all');        % close all open files
        delete(timerfindall); % Delete Timers
    end

    function KeyDown(hObject, event, handles)
        isKeyUp = false;
        key = get(hObject,'CurrentKey');
        KeyStatus = (strcmp(key, KeyNames) | KeyStatus);
    end

    function KeyUp(hObject, event, handles)
        isKeyUp = true;
        key = get(hObject,'CurrentKey');
        KeyStatus = (~strcmp(key, KeyNames) & KeyStatus);
    end

    function Close(hObject, eventdata, handles)
        isProcessing = false;
        delete(hObject);
    end

    % helper functions
    function [value] = LinearInterpolate(x1, x2, mu)
        value = x1 * (1 - mu) + x2 * mu;
    end

%% Setup
    nPts = 100;                       % number of points to display on stripchart
    hLine = StripChartXY('Initialize',nPts);
    set(hLine, 'Color', [0.0 0.9725 0.0])
    figureHandle = gcf;               % current figure handle
    axesHandle = get(figureHandle,'CurrentAxes');
    set(axesHandle, 'XTickLabel', []) % remove numbers
    set(axesHandle, 'YGrid', 'on')
    set(axesHandle, 'YColor', [0.0 0.9725 0.0])
    axis ([0 nPts -1 1]);
    steer = 0;
    timer = now();
    FRAME_DELAY = 0.03;               % 30ms ~ 33.3 FPS

%% Input Callbacks
    set(figureHandle,'CloseRequestFcn',... %# Set the CloseRequestFcn for the figure
        @Close);
    set(figureHandle,'KeyPressFcn',...     %# Set the ButtonDownFcn for the figure
        @KeyDown);
    set(figureHandle,'KeyReleaseFcn',...   %# Set the ButtonDownFcn for the image
        @KeyUp);

%% Input Handle
    KeyStatus = false(1,5);
    KeyNames  = {'w', 's', 'a', 'd', 'q'};
    KEY.UP    = 1;
    KEY.DOWN  = 2;
    KEY.LEFT  = 3;
    KEY.RIGHT = 4;
    KEY.QUIT  = 5;

%% Some constants and variables
    steerDeltaTimeAccumulated = 0;
    % Thresholds of time in milliseconds
    firstDelta           = 0.05;
    secondDelta          = 0.1;
    thirdDelta           = 0.2;

    % Steering values for thresholds
    firstSteerThreshold  = 0.3;
    secondSteerThreshold = 0.5;
    thirdSteerThreshold  = 0.8;
    centeringFactor      = 0.3;

    % Keyboard state for steering
    % 'A' key       -- [-1]
    % 'D' key       -- [1]
    %  release keys -- [0]
    targetSteer = 0;
    steeringValueStart = 0;

    % The result value of smoothing steering
    steer = 0;

 %% Processing
    while isProcessing
        secToWait = FRAME_DELAY - (now() - timer)/86400;
        if secToWait > 0
            pause( secToWait ); % freeze program for each frame
        end

        % Get Input
        if KeyStatus(KEY.QUIT)
            ClearAll();
            break
        elseif KeyStatus(KEY.LEFT) || isKeyUp % If LEFT key is pressed
            if isKeyUp
                targetSteer = 0;
            else
                targetSteer = -1;
            end
            if (targetSteer * steer) < 0.0
                steeringValueStart = 0.0;
            else
                % in that case if we will be frequently press the button
                % we can stay in a certain range of the steering
                % just use current steering value as a base for the next
                steeringValueStart = steer;
            end
            steerDeltaTimeAccumulated = 0;
        elseif KeyStatus(KEY.RIGHT) || isKeyUp % If RIGHT key is pressed
            if isKeyUp
                targetSteer = 0;
            else
                targetSteer = 1;
            end
            if (targetSteer * steer) < 0.0
                steeringValueStart = 0.0;
            else
                steeringValueStart = steer;
            end
            steerDeltaTimeAccumulated = 0;
        end

        if targetSteer ~= steer
            if (targetSteer == 0) && (steer ~= 0)
                % Counter steering
                steer = steer - (steer * centeringFactor);
                nearZero = 0.1;
                if abs(steer) < nearZero
                    steer = 0;
                end
            else
                % Smoothing of steering
                fraction = 1.0;
                steerDeltaTimeAccumulated = steerDeltaTimeAccumulated + secToWait;
                if steerDeltaTimeAccumulated < firstDelta
                    ratio = steerDeltaTimeAccumulated / firstDelta;
                    fraction = LinearInterpolate(0.0, firstSteerThreshold, ratio);
                elseif steerDeltaTimeAccumulated < secondDelta
                    ratio = (steerDeltaTimeAccumulated - firstDelta) / (secondDelta - firstDelta);
                    fraction = LinearInterpolate(firstSteerThreshold, secondSteerThreshold, ratio);
                elseif steerDeltaTimeAccumulated < thirdDelta
                    ratio = (steerDeltaTimeAccumulated - secondDelta) / (thirdDelta - secondDelta);
                    fraction = LinearInterpolate(secondSteerThreshold, thirdSteerThreshold, ratio);
                else
                    steer = targetSteer;
                end

                steer = targetSteer * fraction + steeringValueStart;

                % Clamp steer value between range[-1,1]
                steer = min(1, max(-1, steer));
            end
        end

        % Draw chart
        if ishandle(hLine)
            StripChartXY('Update', hLine, now(), steer);
        end
    end

    ClearAll();
end
