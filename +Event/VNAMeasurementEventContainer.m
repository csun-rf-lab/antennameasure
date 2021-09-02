classdef VNAMeasurementEventContainer < handle
% See comments in MotionControllerStateChangeEvent.m

    properties
        % None?
    end

    events
        Measurement
    end

    methods
        function onMeasurement(obj, state)
            notify(obj, "Measurement", Event.VNAMeasurementEvent(state));
        end
    end
end