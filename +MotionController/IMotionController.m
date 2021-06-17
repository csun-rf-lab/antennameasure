classdef IMotionController< handle
    %IMOTIONCONTROLLER Interface class

    % TODO: Rename this. It probably should be AbstractMotionController
    % at this point...

    properties (SetAccess = protected, GetAccess = protected)
        axes % vector of all axis identifiers
        cb   % callback function handle
        log  % Logger object
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
        function stopAll(obj)
            %stopAll stops motion on all axes, one at a time.
            %   If specific motion controller supports it, this method
            %   can be overridden to stop all axes at once.
            for x = 1:length(obj.axes)
                obj.stop(obj.axes(x))
            end
        end

        function setOnStateChangeCallback(obj, cb)
            obj.cb = cb;
        end

        function clearOnStateChangeCallback(obj)
            clear obj.cb;
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

            if isa(obj.cb, 'function_handle')
                obj.cb(state);
            end
        end
    end
end