classdef (ConstructOnLoad) JobRunnerStateChangeEvent < event.EventData
    properties
        Running = false
        PercentComplete = 0
        Fault = false
    end

    methods
        % See notes in MotionControllerStateChangeEvent.
        function eventData = JobRunnerStateChangeEvent(running, percentComplete, fault)
            eventData.Running = running;
            eventData.PercentComplete = percentComplete;
            eventData.Fault = fault;
        end
    end
end