classdef MI4190 < MotionController.IMotionController
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

             assert(isvector(axes), 'axes must be a vector.');

            obj.axes = axes;
            obj.log = logger;

% Alternative approach to dealing with axes:
%             % count available axes
%             fprintf(obj.Ser, 'CONT1:AXIS:COUN');
%             c = char(fread(obj.Ser, 4))';
%             % TODO: MATLAB suggests this instead (I think):
%             %c = fread(obj.Ser, 4, '*char')';
%             obj.axes = unit8(str2double(c));
% ^^^ This may need a regex, like used in getStatus().
        end

        function ct = getErrorCount(obj)
            %getErrorCount Return the number of errors in the queue.

            try
                obj.send('SYST:ERR:COUN');
                c = obj.recv(4);
                ct = uint8(str2double(c));
            catch e
                disp(e);
                obj.log.Error(e.message);
            end
        end

        function errs = getErrors(obj)
            %getErrors Return all errors in the queue.

            try
                send('SYST:ERR:ALL?');
                errs = obj.recv(1024);
            catch e
                disp(e);
                obj.log.Error(e.message);
            end
        end

        function clearErrors(obj)
            %clearErrors Clear all errors in the queue.
            %   See also getErrorCount() and getErrors().

            try
                obj.send('*CLS');
            catch e
                disp(e);
                obj.log.Error(e.message);
            end
        end

        function name = getName(obj, axis)
            %getName Get the name of a specific axis.

            assert(ismember(axis, obj.axes), 'axis must be a valid axis.');

            if obj.connected
                try
                    obj.send(sprintf('CONT1:AXIS(%d):NAME?', axis));
                    name = obj.recv(100);
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
                obj.send(sprintf('CONT1:AXIS(%d):UNIT:POS?', axis));
                c = obj.recv(1);
                unitsNum = unit8(str2double(c));

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
                        error('Unexpected position units response from controller');
                end
            catch e
                disp(e);
                obj.log.Error(e.message);
                units = -1; % TODO: better error result
            end
        end

        function moveTo(obj, axis, position)
            %moveTo Move a specific axis to a specific position.
            %   Axis is numerical, and position is... probably in degrees.
            % TODO: CHECK UNITS FOR POSITION.
            
            assert(ismember(axis, obj.axes), 'axis must be a valid axis.');
            % TODO: position validation

            try
                obj.state = MotionController.MotionControllerStateEnum.Moving;
                obj.send(sprintf('CONT1:AXIS(%d):POS:COMM %f\n', axis, position));
                obj.send(sprintf('CONT1:AXIS(%d):MOT:STAR', axis));
                obj.waitPosition(axis, position);
                obj.state = MotionController.MotionControllerStateEnum.Stopped;
            catch e
                disp(e);
                obj.log.Error(e.message);
            end
        end

        function moveIncremental(obj, axis, increment)
            % TODO
        end

        function stop(obj, axis)
            %stop Stop motion on a specific axis.

            assert(ismember(axis, obj.axes), 'axis must be a valid axis.');

            try
                obj.send(sprintf('CONT1:AXIS(%d):MOT:STOP', axis));
            catch e
                disp(e);
                obj.log.Error(e.message);
            end
        end

        function pos = getPosition(obj, axis)
            %getPosition Return the current position of an axis as a
            %double.

            assert(ismember(axis, obj.axes), 'axis must be a valid axis.');

            try
                obj.send(sprintf('CONT1:AXIS(%d):POS:CURR?', axis));
                posChar = obj.recv(100);
                pos = str2double(convertCharsToStrings(posChar));
            catch e
                disp(e);
                obj.log.Error(e.message);
                pos = -99999999999;
            end
        end

        function waitPosition(obj, axis, position)
            assert(ismember(axis, obj.axes), 'axis must be a valid axis.');

% TODO *******************************************************
% The code I found on github is a bit of a mess. Might need to
% actually play with the controller to see how to write this best.
% TODO *******************************************************
            % TODO: include a timeout?
        end

        function waitIdle(obj, axis)
            %waitIdle Query the controller for the axis velocity, and don't
            %return until the velocity is zero.

            assert(ismember(axis, obj.axes), 'axis must be a valid axis.');

            vel = obj.getVelocity(axis);
            while (vel ~= 0.0000)
                pause(1.5); % don't over-burden the controller
                vel = obj.getVelocity(axis);
            end

            % TODO: Add user-controllable timeout property. (prop on obj?)
            % If the timeout is exceeded, throw an error.
        end

        function vel = getVelocity(obj, axis)
            %getVelocity Return the current velocity of an axis as a
            %double.

            assert(ismember(axis, obj.axes), 'axis must be a valid axis.');

            try
                obj.send(sprintf('CONT1:AXIS(%d):VEL:CURR?', axis));
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

            assert(ismember(axis, obj.axes), 'axis must be a valid axis.');

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
                obj.send(sprintf('CONT1:AXIS(%d):STAT?', axis));
                currStat = obj.recv(100);

                intStat = uint16(str2double(regexp(currStat,'\d*','match')));

                status = '';
                for b = 1:length(statuses)
                    if bitget(intStat, b) == 1
                        if length(status) ~= 0
                            status = strcat(status, ", ");
                        end
                        status = strcat(status, statuses(b));
                    end
                end
            catch e
                disp(e);
                obj.log.error(e.message);
            end
        end % end getStatus()

        function stopAll(obj)
            %stopAll Stop motion on all axes, all at once.

            try
                obj.send('CONT1:ABORT');
            catch e
                disp(e);
                obj.log.Error(e.message);
            end
        end
    end % end methods
end