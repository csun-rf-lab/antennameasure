classdef MotionControllerStateChangeContainer < handle
% See comments in MotionControllerStateChangeEvent.m

    properties
        % None?
    end

    events
        StateChange
    end

    methods
        function onStateChange(obj, state)
            notify(obj, "StateChange", Event.MotionControllerStateChangeEvent(state));
        end
    end
end