classdef Dummy < MotionController.IMotionController
    %DUMMY Test class for motion controller interfaces.
    %   See MI4190 class for more detail about how these classes should
    %   work in general.

    properties
        % axes, in superclass
        % log,  in superclass
        state % State
        positions
        addr
    end

    methods
        function obj = Dummy(axes, logger)
            obj.axes = axes;
            obj.log = logger;

            obj.positions = zeros(1, length(axes));
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
                "AZ Axis",
                "AUTROLL Axis",
                "Tx Pol Axis"
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

        function obj = moveTo(obj, axis, position)
            assert(ismember(axis, obj.axes), 'axis must be a valid axis.');

            obj.log.Debug(sprintf("Dummy::moveTo(%d, %f): MOVING", axis, position));
            obj.state = MotionController.MotionControllerStateEnum.Moving;
            obj.positions(axis) = position;
            obj.waitPosition(axis, position);
            obj.state = MotionController.MotionControllerStateEnum.Stopped;
            obj.log.Debug(sprintf("Dummy::moveTo(%d, %f): STOPPED", axis, position));
        end

        function obj = moveIncremental(obj, axis, increment)
            assert(ismember(axis, obj.axes), 'axis must be a valid axis.');

            obj.log.Debug(sprintf("Dummy::moveIncremental(%d, %f): MOVING", axis, increment));
            obj.state = MotionController.MotionControllerStateEnum.Moving;
            obj.positions(axis) = obj.positions(axis) + increment;
            obj.waitIdle(axis);
            obj.state = MotionController.MotionControllerStateEnum.Stopped;
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

        function waitPosition(obj, axis, position)
            assert(ismember(axis, obj.axes), 'axis must be a valid axis.');

            obj.log.Debug(sprintf("Dummy::waitPosition(%d, %f)", axis, position));
            pause(2);
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

        function obj = setGPIBAddress(obj, addr)
            obj.addr = uint8(addr);
            obj.log.Info(sprintf("Changed target GPIB address to %d", obj.addr));
        end

        function addr = getGPIBAddress(obj)
            addr = obj.addr;
            obj.log.Debug(sprintf("Dummy::getGPIBAddress(): %d", addr));
        end
    end % end methods
end