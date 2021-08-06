classdef AbstractMotionController< handle
    %ABSTRACTMOTIONCONTROLLER Base class

    properties (SetAccess = protected, GetAccess = protected)
        connected = false % bool: connected to controller?
        axes % vector of all axis identifiers
        cb   % callback function handle
        ec   % Container for emitting events
        log  % Logger object
        onConnectStateChangeCb
    end

    methods (Abstract)
        moveTo(obj, axis, position)
        % Move a specific axis to a specific position.

        moveIncremental(obj, axis, increment)
        % Move a specific amount from current position.

        stop(obj, axis)
        % Stop all motion on specific axis.

        getPosition(obj, axis)
        % Return the current position of an axis as a double.

        waitPosition(obj, axis, position)
        % Wait for a specific axis to reach a specific position.

        waitIdle(obj, axis)
        % Wait for a specific axis to be idle.

        getVelocity(obj, axis)
        % Return the current velocity of an axis as a double.
    end

    methods
        function obj = AbstractMotionController()
            obj.ec = Event.MotionControllerStateChangeContainer;
        end

        function ec = getEventContainer(obj)
            ec = obj.ec;
        end

        function conn = isConnected(obj)
            conn = obj.connected;
        end

        function stopAll(obj)
            %stopAll stops motion on all axes, one at a time.
            %   If specific motion controller supports it, this method
            %   can be overridden to stop all axes at once.
            for x = 1:length(obj.axes)
                obj.stop(obj.axes(x))
            end
        end

        function setOnConnectStateChangeCallback(obj, cb)
            obj.onConnectStateChangeCb = cb;
        end

        function clearOnConnectStateChangeCallback(obj)
            clear obj.onConnectStateChangeCb;
        end
    end

    methods (Access = protected)
        function onStateChange(obj, axis, moving, fault, position)
            % onStateChange called by extending class when a state change
            % occurs. This method collects the relevant information and
            % calls the state change callback.

            state = MotionController.AxisState();
            state.axis = axis;
            state.moving = moving;
            state.fault = fault;
            state.position = position;

            % I couldn't figure out a sane way to emit events from here,
            % so we go through this other class:
            obj.ec.onStateChange(state);

            if isa(obj.cb, 'function_handle')
                obj.cb(state);
            end
        end

        function setConnectedState(obj, state)
            obj.connected = state;
            if isa(obj.onConnectStateChangeCb, 'function_handle')
                obj.onConnectStateChangeCb(obj.connected);
            end
        end
    end
end