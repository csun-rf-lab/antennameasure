classdef MI4190 < MotionController.AbstractMotionController
    %MI4190 Class for controlling MI-4190 motion controller.
    %   This class must be provided a serialport object in the constructor,
    %   and can be used to control any number of axes on the controller.
    %
    %   Right now this class assumes it is only talking to one controller,
    %   with id 1.

    % TODO: Look at using a mutex to lock the serial port between
    % write/read.

    % TODO: Support moving multiple axes at once. Right now this will only
    % handle moving one axis at a time, which could be incredibly tedious
    % when switching between steps of a job.

    properties
        % axes, in superclass
        % log,  in superclass
        state % State
    end

    methods
        function obj = MI4190(axes, logger)
            %MI4190 Construct an instance of this class
            %   axes is a vector of all axes identifiers.

             assert(isvector(axes), "axes must be a vector.");

            obj.axes = axes;
            obj.log = logger;
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

            assert(ismember(axis, obj.axes), "axis must be a valid axis.");

            if obj.connected
                try
                    obj.send(sprintf("CONT1:AXIS(%d):NAME?", axis));
                    name = obj.recv(32);
                catch e
                    disp(e);
                    obj.log.Error(e.message);
                    name = "Unknown";
                end
            else
                name = "Unknown";
            end
        end

        function units = getPosUnits(obj, axis)
            %getPosUnits Get the position units for a specific axis.
            %   See MI4190PosUnits enum.

            try
                obj.send(sprintf("CONT1:AXIS(%d):UNIT:POS?", axis));
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
            try
                obj.send(sprintf("CONT1:AXIS(%d):POS:LIM:FEN?", axis));
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
            try
                obj.send(sprintf("CONT1:AXIS(%d):POS:LIM:REN?", axis));
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
            try
                obj.send(sprintf("CONT1:AXIS(%d):POS:LIM:FORW?", axis));
                limStr = obj.recv(16);
                lim = str2double(limStr);
            catch e
                disp(e);
                obj.log.Error(e.message);
            end
        end

        function lim = getReverseSoftLimit(obj, axis)
            try
                obj.send(sprintf("CONT1:AXIS(%d):POS:LIM:REV?", axis));
                limStr = obj.recv(16);
                lim = str2double(limStr);
            catch e
                disp(e);
                obj.log.Error(e.message);
            end
        end

        function moveTo(obj, axis, position)
            %moveTo Move a specific axis to a specific position.
            %   Axis is numerical, and position is in whatever units
            %   getPosUnits() says the units should be.
            
            assert(ismember(axis, obj.axes), "axis must be a valid axis.");
            % TODO: position validation

            try
                pos = obj.getPosition(axis);
                obj.onStateChange(axis, true, false, pos);
                obj.state = MotionController.MotionControllerStateEnum.Moving;
                obj.send(sprintf("CONT1:AXIS(%d):POS:COMM %f\n", axis, position));
                obj.send(sprintf("CONT1:AXIS(%d):MOT:STAR", axis));
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
            assert(ismember(axis, obj.axes), "axis must be a valid axis.");

            try
                pos = obj.getPosition(axis);
                obj.onStateChange(axis, true, false, pos);
                obj.state = MotionController.MotionControllerStateEnum.Moving;
                obj.send(sprintf("CONT1:AXIS(%d):POS:INCR %f\n", axis, increment));
                obj.send(sprintf("CONT1:AXIS(%d):MOT:STAR", axis));
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

            assert(ismember(axis, obj.axes), "axis must be a valid axis.");

            try
                obj.send(sprintf("CONT1:AXIS(%d):MOT:STOP", axis));
            catch e
                disp(e);
                obj.log.Error(e.message);
            end
        end

        function pos = getPosition(obj, axis)
            %getPosition Return the current position of an axis as a
            %double.

            assert(ismember(axis, obj.axes), "axis must be a valid axis.");

            try
                obj.send(sprintf("CONT1:AXIS(%d):POS:CURR?", axis));
                posChar = obj.recv(100);
                pos = str2double(convertCharsToStrings(posChar));
            catch e
                disp(e);
                obj.log.Error(e.message);
                pos = -99999999999;
            end
        end

        function waitPosition(obj, axis, position)
            assert(ismember(axis, obj.axes), "axis must be a valid axis.");

            thresh = 0.07; % +/- this many degrees
            pos = obj.getPosition(axis);
            while abs(pos - position) > thresh
                f = obj.hasFault(axis);
                obj.onStateChange(axis, true, f, pos);

                % Check if user aborted
                if obj.state == MotionController.MotionControllerStateEnum.Stopped
                    break;
                end

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

            assert(ismember(axis, obj.axes), "axis must be a valid axis.");
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

            assert(ismember(axis, obj.axes), "axis must be a valid axis.");

            try
                obj.send(sprintf("CONT1:AXIS(%d):VEL:CURR?", axis));
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

            assert(ismember(axis, obj.axes), "axis must be a valid axis.");

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
                obj.send(sprintf("CONT1:AXIS(%d):STAT?", axis));
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
            assert(ismember(axis, obj.axes), "axis must be a valid axis.");

            fault = true;
            try
                obj.send(sprintf("CONT1:AXIS(%d):STAT?", axis));
                currStat = obj.recv(100);

                intStat = uint16(str2double(regexp(currStat, "\d*", "match")));
                if bitget(intStat, 5) == 1
                    fault = true;
                    obj.log.Error("Fault!");
                else
                    fault = false;
                end
            catch e
                disp(e);
                obj.log.Error(e.message);
            end
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
    end % protected methods
end