classdef Dummy < MotionController.AbstractMotionController
    %DUMMY Test class for motion controller interfaces.
    %   See MI4190 class for more detail about how these classes should
    %   work in general.

    properties
        % axes, in superclass
        % log,  in superclass
        state % State
        positions
        addr
        comport
    end

    methods
        function obj = Dummy(logger)
            obj.axes = [1 2 3];
            obj.log = logger;

            obj.positions = zeros(1, length(obj.axes));
            obj.addr = 4;

            obj.log.Info("Instantiated dummy motion controller");
        end

        function ct = getErrorCount(obj)
            obj.log.Debug("Dummy::getErrorCount(): 0");
            ct = 0;
        end

        function errs = getErrors(obj)
            obj.log.Debug("Dummy::getErrors(): [none]");
            errs = "";
        end

        function clearErrors(obj)
            obj.log.Debug("Dummy::clearErrors()");
        end

        function name = getName(obj, axis)
            axes = {
                "AZ Axis (TEST)",
                "AUTROLL Axis (TEST)",
                "Tx Pol Axis (TEST)"
            };

            assert(ismember(axis, obj.axes), 'axis must be a valid axis.');
            name = string(axes(axis));
            obj.log.Debug(sprintf("Dummy::getName(%d): %s", axis, name));
        end

        function units = getPosUnits(obj, axis)
            assert(ismember(axis, obj.axes), 'axis must be a valid axis.');

            obj.log.Debug(sprintf("Dummy::getPosUnits(%d)", axis));
            units = MotionController.MI4190PosUnits.Degree;
        end

        function lim = getForwardSoftLimit(obj, axis)
            switch axis
                case 1
                    lim = 90;
                case 2
                    lim = 180;
                case 3
                    lim = 180;
                otherwise
                    lim = 11;
            end
        end

        function lim = getReverseSoftLimit(obj, axis)
            switch axis
                case 1
                    lim = -90;
                case 2
                    lim = -180;
                case 3
                    lim = -180;
                otherwise
                    lim = -11;
            end
        end

        function slew = getSlewVelocity(obj, axis)
            slew = 4;
        end

        function actual = setSlewVelocity(obj, axis, slew)
            actual = slew;
        end

        function moveTo(obj, axes, positions)
            for a = 1:length(axes)
                assert(ismember(axes(a), obj.axes), "axis must be a valid axis.");
            end

            for a = 1:length(axes)
                obj.log.Debug(sprintf("Dummy::moveAxisTo(%d, %f): MOVING", axes(a), positions(a)));
            end

            obj.state = MotionController.MotionControllerStateEnum.Moving;

            for a = 1:length(axes)
                axis = axes(a);
                start = obj.positions(axis);
                desired = positions(a);
                obj.positions(axis) = start + (desired - start)/2;
            end

            obj.waitPositionMultiple(axes, positions);

            obj.state = MotionController.MotionControllerStateEnum.Stopped;
            for a = 1:length(axes)
                obj.log.Debug(sprintf("Dummy::moveAxisTo(%d, %f): STOPPED", axes(a), positions(a)));
            end
        end

        function moveAxisTo(obj, axis, position)
            assert(ismember(axis, obj.axes), 'axis must be a valid axis.');

            obj.log.Debug(sprintf("Dummy::moveAxisTo(%d, %f): MOVING", axis, position));
            obj.state = MotionController.MotionControllerStateEnum.Moving;
            start = obj.positions(axis);

            obj.positions(axis) = start + (position - start)/2;
            obj.onStateChange(axis, true, false, obj.positions(axis));
            obj.waitPosition(axis, position);

            if position == 999
                obj.onStateChange(axis, false, true, obj.positions(axis));
            end

            obj.state = MotionController.MotionControllerStateEnum.Stopped;
            obj.log.Debug(sprintf("Dummy::moveAxisTo(%d, %f): STOPPED", axis, position));
        end

        function moveIncremental(obj, axis, increment)
            assert(ismember(axis, obj.axes), 'axis must be a valid axis.');

            obj.log.Debug(sprintf("Dummy::moveIncremental(%d, %f): MOVING", axis, increment));
            obj.state = MotionController.MotionControllerStateEnum.Moving;
            obj.onStateChange(axis, true, false, obj.positions(axis));
            obj.positions(axis) = obj.positions(axis) + increment;
            obj.waitIdle(axis);
            obj.state = MotionController.MotionControllerStateEnum.Stopped;
            obj.onStateChange(axis, false, false, obj.positions(axis));
            obj.log.Debug(sprintf("Dummy::moveIncremental(%d, %f): STOPPED", axis, increment));
        end

        function stop(obj, axis)
            obj.log.Debug(sprintf("Dummy:stop(%d)", axis));
        end

        function pos = getPosition(obj, axis)
            assert(ismember(axis, obj.axes), 'axis must be a valid axis.');

            obj.log.Debug(sprintf("Dummy::getPosition(%d): %f", axis, obj.positions(axis)));
            pos = obj.positions(axis);
        end

        function pos = getPositionMultiple(obj, axes)
            for a = 1:length(axes)
                assert(ismember(axes(a), obj.axes), "axis must be a valid axis.");
            end

            obj.log.Debug(sprintf("Dummy::getPositionMultiple()"));
            pos = obj.positions(axes);
        end

        function waitPositionMultiple(obj, axes, positions)
            for a = 1:length(axes)
                assert(ismember(axes(a), obj.axes), "axis must be a valid axis.");
            end

            for a = 1:length(axes)
                obj.log.Debug(sprintf("Dummy::waitPosition(%d, %f)", axes(a), positions(a)));
            end

            pause (3);

            for a = 1:length(axes)
                axis = axes(a);
                position = positions(a);
                obj.positions(axis) = position;
                obj.onStateChange(axis, false, false, obj.positions(axis));
            end
        end

        function waitPosition(obj, axis, position)
            assert(ismember(axis, obj.axes), 'axis must be a valid axis.');

            obj.log.Debug(sprintf("Dummy::waitPosition(%d, %f)", axis, position));
            pause(2);

            % set the final position now. we already went halfway there in
            % moveAxisTo().
            obj.positions(axis) = position;
            obj.onStateChange(axis, false, false, obj.positions(axis));
        end

        function waitIdle(obj, axis)
            assert(ismember(axis, obj.axes), 'axis must be a valid axis.');

            obj.log.Debug(sprintf("Dummy::waitIdle(%d)", axis));
            pause(2);
        end

        function vel = getVelocity(obj, axis)
            assert(ismember(axis, obj.axes), 'axis must be a valid axis.');

            obj.log.Debug(sprintf("Dummy::getVelocity(%d)", axis));

            vel = 1.2;
        end

        function status = getStatus(obj, axis)
            assert(ismember(axis, obj.axes), 'axis must be a valid axis.');

            obj.log.Debug(sprintf("Dummy::getStatus(%d)", axis));
        end

        function stopAll(obj)
            obj.log.Debug("Dummy::stopAll()");
        end

        %
        % methods from prologix extension class
        %

        function connect(obj)
            if obj.addr == 1
                obj.setConnectedState(true);
            else
                obj.setConnectedState(false);
            end
        end

        function disconnect(obj)
            obj.setConnectedState(false);
        end

        function setSerialPort(obj, comport)
            obj.comport = comport;
            obj.log.Info(sprintf("Changed target serial port to %s", obj.comport));
            obj.disconnect();
        end

        function comport = getSerialPort(obj)
            comport = obj.comport;
        end

        function setGPIBAddress(obj, addr)
            obj.addr = uint8(addr);
            obj.log.Info(sprintf("Changed target GPIB address to %d", obj.addr));
        end

        function addr = getGPIBAddress(obj)
            addr = obj.addr;
            obj.log.Debug(sprintf("Dummy::getGPIBAddress(): %d", addr));
        end
    end % end methods
end