classdef MI4190 < MotionController.AbstractMotionController
    %MI4190 Class for controlling MI-4190 motion controller.
    %   This class must be provided with the axis ids to be controlled.
    %   The axis numbers used as input to all of the functions are number
    %   sequentially; these reference the axes ids passed in the
    %   constructor, which match the axis numbers on the motion controller.
    %   The sequential ids are just to make the UI simpler to code (and
    %   more flexible and easily modified).
    %
    %   Right now this class assumes it is only talking to one controller,
    %   with id 1.

    % TODO: Look at using a mutex to lock the serial port between
    % write/read.

    properties
        % axes, in superclass
        % log,  in superclass
        state % State
        axisNames % Cache names so we're not looking them up all the time
    end

    methods
        function obj = MI4190(axes, logger)
            %MI4190 Construct an instance of this class
            %   axes is a vector of all axes identifiers.

            assert(isvector(axes), "axes must be a vector.");

            obj.axes = axes;
            obj.log = logger;
            obj.axisNames = repelem("", length(axes));
        end

        function check(obj)
            try
                obj.send("*idn?");
                idn = obj.recv(100);
                obj.log.Info(sprintf("Position Controller ID: %s\n", idn));
                obj.setConnectedState(true);
            catch e
                disp(e);
                obj.log.Error(e.message);
            end
        end

        function ct = getErrorCount(obj)
            %getErrorCount Return the number of errors in the queue.

            try
                obj.send("SYST:ERR:COUN");
                c = obj.recv(4);
                ct = uint8(str2double(c));
            catch e
                disp(e);
                obj.log.Error(e.message);
            end
        end

        function errs = getErrors(obj)
            %getErrors Return all errors in the queue.
% 0, "No error"
            try
                obj.send("SYST:ERR:ALL?");
                errs = obj.recv(100);
                obj.log.Info(sprintf("Errors: %s", errs));
            catch e
                disp(e);
                obj.log.Error(e.message);
            end
        end

        function clearErrors(obj)
            %clearErrors Clear all errors in the queue.
            %   See also getErrorCount() and getErrors().

            try
                obj.send("*CLS");
            catch e
                disp(e);
                obj.log.Error(e.message);
            end
        end

        function name = getName(obj, axis)
            %getName Get the name of a specific axis.

            obj.checkAxisNumber(axis); % validate data

            if isstring(obj.axisNames(axis)) && strlength(obj.axisNames(axis)) > 0
                name = obj.axisNames(axis);
            else
                if obj.connected
                    try
                        obj.send(sprintf("CONT1:AXIS(%d):NAME?", obj.realAxis(axis)));
                        name = obj.recv(32);

                        obj.axisNames(axis) = name;
                    catch e
                        disp(e);
                        obj.log.Error(e.message);
                        name = "Unknown";
                    end
                else
                    name = "Unknown";
                end
            end
        end

        function units = getPosUnits(obj, axis)
            %getPosUnits Get the position units for a specific axis.
            %   See MI4190PosUnits enum.

            obj.checkAxisNumber(axis); % validate data

            try
                obj.send(sprintf("CONT1:AXIS(%d):UNIT:POS?", obj.realAxis(axis)));
                c = obj.recv(4);
                unitsNum = uint8(str2double(c));

                units = MotionController.MI4190PosUnits.Unknown;
                switch unitsNum
                    case 0
                        units = MotionController.MI4190PosUnits.Encoder;
                    case 1
                        units = MotionController.MI4190PosUnits.Meter;
                    case 2
                        units = MotionController.MI4190PosUnits.Centimeter;
                    case 3
                        units = MotionController.MI4190PosUnits.Millimeter;
                    case 4
                        units = MotionController.MI4190PosUnits.Inch;
                    case 5
                        units = MotionController.MI4190PosUnits.Foot;
                    case 6
                        units = MotionController.MI4190PosUnits.Degree;
                    case 7
                        units = MotionController.MI4190PosUnits.Radian;
                    case 8
                        units = MotionController.MI4190PosUnits.Revolution;
                    otherwise
                        error("Unexpected position units response from controller: " + unitsNum);
                end
            catch e
                disp(e);
                obj.log.Error(e.message);
            end
        end

        function enabled = isForwardSoftLimitEnabled(obj, axis)

            obj.checkAxisNumber(axis); % validate data

            try
                obj.send(sprintf("CONT1:AXIS(%d):POS:LIM:FEN?", obj.realAxis(axis)));
                enabledStr = obj.recv(8);

                enabled = false;
                switch str2double(enabledStr)
                    case 0
                        enabled = false;
                    case 1
                        enabled = true;
                    otherwise
                        error("Unexpected soft limit enabled response from controller: " + enabledStr);
                end
            catch e
                disp(e);
                obj.log.Error(e.message);
            end
        end

        function enabled = isReverseSoftLimitEnabled(obj, axis)

            obj.checkAxisNumber(axis); % validate data

            try
                obj.send(sprintf("CONT1:AXIS(%d):POS:LIM:REN?", obj.realAxis(axis)));
                enabledStr = obj.recv(8);

                enabled = false;
                switch str2double(enabledStr)
                    case 0
                        enabled = false;
                    case 1
                        enabled = true;
                    otherwise
                        error("Unexpected soft limit enabled response from controller: " + enabledStr);
                end
            catch e
                disp(e);
                obj.log.Error(e.message);
            end
        end

        function lim = getForwardSoftLimit(obj, axis)

            obj.checkAxisNumber(axis); % validate data

            try
                obj.send(sprintf("CONT1:AXIS(%d):POS:LIM:FORW?", obj.realAxis(axis)));
                limStr = obj.recv(16);
                lim = str2double(limStr);
            catch e
                disp(e);
                obj.log.Error(e.message);
            end
        end

        function lim = getReverseSoftLimit(obj, axis)

            obj.checkAxisNumber(axis); % validate data

            try
                obj.send(sprintf("CONT1:AXIS(%d):POS:LIM:REV?", obj.realAxis(axis)));
                limStr = obj.recv(16);
                lim = str2double(limStr);
            catch e
                disp(e);
                obj.log.Error(e.message);
            end
        end

        function moveTo(obj, axes, positions)
            %moveTo Move a set of axes to specific positions.
            %   Axes is a numerical vector, and positions a vector
            %   with the same length as axes.

            for a = 1:length(axes)
                obj.checkAxisNumber(axes(a)); % validate data
            end
            % TODO: position validation

%            try
                for a = 1:length(axes)
                    axis = axes(a);
                    pos = obj.getPosition(axis);
                    obj.onStateChange(axis, true, false, pos);
                end

                obj.state = MotionController.MotionControllerStateEnum.Moving;

                for a = 1:length(axes)
                    axis = axes(a);
                    position = positions(a);
                    obj.send(sprintf("CONT1:AXIS(%d):POS:COMM %f\n", obj.realAxis(axis), position));
                    obj.send(sprintf("CONT1:AXIS(%d):MOT:STAR", obj.realAxis(axis)));
                    pause(0.5);
                end

                obj.waitPositionMultiple(axes, positions);

                obj.state = MotionController.MotionControllerStateEnum.Stopped;

                for a = 1:length(axes)
                    pos = obj.getPosition(axis);
                    obj.onStateChange(axis, false, false, pos);
                end
%            catch e
%                disp(e);
%                obj.log.Error(e.message);
%            end
        end

        function moveAxisTo(obj, axis, position)
            %moveAxisTo Move a specific axis to a specific position.
            %   Axis is numerical, and position is in whatever units
            %   getPosUnits() says the units should be.

            obj.checkAxisNumber(axis); % validate data
            % TODO: position validation

            try
%                 pos = obj.getPosition(axis);
%                 obj.onStateChange(axis, true, false, pos);
                 obj.state = MotionController.MotionControllerStateEnum.Moving;
%                obj.fread(); % clear out any junk in the incoming queue
                obj.send(sprintf("CONT1:AXIS(%d):POS:COMM %f\n", obj.realAxis(axis), position));

                %pause(0.1);

                % Verify the commanded position
                obj.send(sprintf("CONT1:AXIS(%d):POS:COMM?\n", obj.realAxis(axis)));
                commStr = obj.recv(16);
                comm = str2double(commStr);
                if comm ~= position
                    obj.log.Error("Commanded position doesn't match what we specified!");
                end

                %pause(0.1);

                % Start motion
                obj.send(sprintf("CONT1:AXIS(%d):MOT:STAR", obj.realAxis(axis)));
                obj.waitPosition(axis, position);
                obj.state = MotionController.MotionControllerStateEnum.Stopped;
                pos = obj.getPosition(axis);
                obj.onStateChange(axis, false, false, pos);
            catch e
                disp(e);
                obj.log.Error(e.message);
            end
        end

        function moveIncremental(obj, axis, increment)
            obj.checkAxisNumber(axis); % validate data

            try
                pos = obj.getPosition(axis);
                obj.onStateChange(axis, true, false, pos);
                obj.state = MotionController.MotionControllerStateEnum.Moving;
                obj.send(sprintf("CONT1:AXIS(%d):POS:INCR %f\n", obj.realAxis(axis), increment));
                obj.send(sprintf("CONT1:AXIS(%d):MOT:STAR", obj.realAxis(axis)));
                obj.waitIdle(axis);
                obj.state = MotionController.MotionControllerStateEnum.Stopped;
                pos = obj.getPosition(axis);
                obj.onStateChange(axis, false, false, pos);
            catch e
% TODO: Check if axis is moving. May need to update state to Stopped.
                disp(e);
                obj.log.Error(e.message);
            end
        end

        function stop(obj, axis)
            %stop Stop motion on a specific axis.

            obj.checkAxisNumber(axis); % validate data

            try
                obj.send(sprintf("CONT1:AXIS(%d):MOT:STOP", obj.realAxis(axis)));
            catch e
                disp(e);
                obj.log.Error(e.message);
            end
        end

        function pos = getPosition(obj, axis)
            %getPosition Return the current position of an axis as a
            %double.

            obj.checkAxisNumber(axis); % validate data

            try
                pos = str2double("nan");
                attempts = 0;
                while isnan(pos) && attempts < 5 % Try up to 5 times if we get bad data
                    if attempts > 0
                        % If first attempt didn't work, pause for a moment
                        % before we try again.
                        pause(0.2);
                    end

                    obj.send(sprintf("CONT1:AXIS(%d):POS:CURR?", obj.realAxis(axis)));
                    posChar = obj.recv(100);
                    pos = str2double(convertCharsToStrings(posChar));
                    attempts = attempts + 1;
                    if attempts > 1
                        obj.log.Warn(sprintf("getPosition(): Reattempt (%d total attempts)", attempts));
                    end
                end
            catch e
                disp(e);
                obj.log.Error(e.message);
                pos = -99999999999;
            end
        end

        function pos = getPositionMultiple(obj, axes)
            pos = zeros(1, length(axes));
            for a = 1:length(axes)
% TODO: Do we need a delay in here?
                pos(a) = obj.getPosition(axes(a));
            end
        end

        function waitPositionMultiple(obj, axes, positions)
            for a = 1:length(axes)
                obj.checkAxisNumber(axes(a)); % validate data
            end

            thresh = 0.5; % +/- this many degrees (TxPol is as bad as 0.4)
            pos = obj.getPositionMultiple(axes);
            while abs(pos - positions) > thresh
                for a = 1:length(axes)
                    axis = axes(a);
                    f = obj.hasFault(axis);
                    obj.onStateChange(axis, true, f, pos(a));
                end

                % Check if user aborted
                if obj.state == MotionController.MotionControllerStateEnum.Stopped
                    break;
                end

                pause(0.5);
                pos = obj.getPositionMultiple(axes);
            end
% TODO: Alternatively, check the axis status to see when it has stopped
% moving?

% TODO: Confirm we're no longer moving
            for a = 1:length(axes)
                axis = axes(a);
                f = obj.hasFault(axis);
                obj.onStateChange(axis, true, f, pos(a));
            end

% TODO: include a timeout?
        end

        function waitPosition(obj, axis, position)
            thresh = 0.5; % +/- this many degrees (TxPol is as bad as 0.4)
            pos = obj.getPosition(axis);
            while abs(pos - position) > thresh
                f = obj.hasFault(axis);
                obj.onStateChange(axis, true, f, pos);

%                 % Check if user aborted
%                 if obj.state == MotionController.MotionControllerStateEnum.Stopped
%                     break;
%                 end

                pause(0.5);

                pos = obj.getPosition(axis);
            end
% TODO: Alternatively, check the axis status to see when it has stopped
% moving?

% TODO: Confirm we're no longer moving
obj.onStateChange(axis, false, false, pos);

% TODO: include a timeout?
        end

        function waitIdle(obj, axis)
            %waitIdle Query the controller for the axis velocity, and don't
            %return until the velocity is zero.

% TODO: Maybe get status instead, and wait until axis not in motion?
% This would make it easier to watch for limits/faults/etc.

            % velocity is 0 initially (because it hasn't started moving
            % yet) so pause for a moment before checking it.
            pause(1);
            vel = obj.getVelocity(axis);
            while (vel ~= 0.0000)
                pos = obj.getPosition(axis);
                f = obj.hasFault(axis);
                obj.onStateChange(axis, true, f, pos);
                pause(0.5); % don't over-burden the controller
                vel = obj.getVelocity(axis);
            end

            pos = obj.getPosition(axis);
            obj.onStateChange(axis, false, false, pos);

            % TODO: Add user-controllable timeout property. (prop on obj?)
            % If the timeout is exceeded, throw an error.
        end

        function vel = getVelocity(obj, axis)
            %getVelocity Return the current velocity of an axis as a
            %double.

            obj.checkAxisNumber(axis); % validate data

            try
                obj.send(sprintf("CONT1:AXIS(%d):VEL:CURR?", obj.realAxis(axis)));
                velChar = obj.recv(100);
                vel = str2double(convertCharsToStrings(velChar));
            catch e
                disp(e);
                obj.log.Error(e.message);
            end
        end

        function status = getStatus(obj, axis)
            %getStatus Get and return the current status values of Axis.
            %   Axis status is returned as an integer representing a 16-bit number,
            %   where each bit has a respective meaning for the axis status options.
            %   This function gets that value, and decodes each bit, returning a list
            %   of the different status values of the axis at a moment in time.
            %   Details on page 3-42 of MI-4192 Manual.

            obj.checkAxisNumber(axis); % validate data

            % Lookup table from the manual (page 3-42).
            % Note that here the "bit number" starts from 1 (because
            % MATLAB...) whereas in the manual (and normal rational human
            % thought) the bits start from #0. The comments indicate the
            % bit numbers per the manual.
            statuses = {
                'latch is set',            % 0
                'home switch active',      % 1
                'reverse limit active',    % 2
                'forward limit active',    % 3
                'PAU fault',               % 4
                'axis enabled',            % 5
                'error limit active',      % 6
                'axis in motion',          % 7
                'axis is active',          % 8
                'axis is indexed',         % 9
                'position trigger active', % 10
                'property changed',        % 11
                'status changed',          % 12
                'unknown',                 % 13: unused
                'unknown',                 % 14: unused
                'unknown'                  % 15: unused
            };

            try
                obj.send(sprintf("CONT1:AXIS(%d):STAT?", obj.realAxis(axis)));
                currStat = obj.recv(100);

                intStat = uint16(str2double(regexp(currStat, "\d*", "match")));

                status = '';
                for b = 1:length(statuses)
                    if bitget(intStat, b) == 1
                        if length(status) ~= 0
                            status = strcat(status, ", ");
                        end
                        status = strcat(status, string(statuses(b)));
                    end
                end

                obj.log.Info(sprintf("Status: %s", status));
            catch e
                disp(e);
                obj.log.Error(e.message);
            end
        end % end getStatus()

        function fault = hasFault(obj, axis)
            % see also getStatus()
            obj.checkAxisNumber(axis); % validate data

            fault = true;
%            try
                obj.send(sprintf("CONT1:AXIS(%d):STAT?", obj.realAxis(axis)));
                currStat = obj.recv(100);

                intStat = uint16(str2double(regexp(currStat, "\d*", "match")));
                if bitget(intStat, 5) == 1
                    fault = true;
                    obj.log.Error("Fault!");
                else
                    fault = false;
                end
%            catch e
%                disp(e);
%                obj.log.Error(e.message);
%            end
        end

        function stopAll(obj)
            %stopAll Stop motion on all axes, all at once.

            try
                obj.send("CONT1:ABORT");
% TODO: Verify that we stopped.
                obj.state = MotionController.MotionControllerStateEnum.Stopped;
            catch e
                disp(e);
                obj.log.Error(e.message);
            end
        end
    end % end methods

    methods (Access = protected)
        % Overridden in Prologix class
        function send(obj, msg)
        end

        % Overridden in Prologix class
        function msg = recv(obj, len)
        end

        % Overridden in Prologix class
        function data = fread(obj)
        end

        function checkAxisNumber(obj, axis)
            assert(ismember(axis, 1:length(obj.axes)), "axis must be a valid axis.");
        end

        function x = realAxis(obj, axis)
            % REALAXIS returns the actual axis number referenced by the UI
            x = obj.axes(axis);
        end
    end % protected methods
end