classdef (ConstructOnLoad) JobRunnerMeasurementsChangeEvent < event.EventData
    properties
        Positions
        S21
    end

    methods
        function eventData = JobRunnerMeasurementsChangeEvent(positions, S21)
            eventData.Positions = positions;
            eventData.S21 = S21;
        end
    end
end