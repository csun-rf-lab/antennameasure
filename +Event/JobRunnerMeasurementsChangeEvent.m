classdef (ConstructOnLoad) JobRunnerMeasurementsChangeEvent < event.EventData
    properties
        Positions
        S21
        TimeRemainingSecs
    end

    methods
        function eventData = JobRunnerMeasurementsChangeEvent(positions, S21, time_remaining_secs)
            eventData.Positions = positions;
            eventData.S21 = S21;
            eventData.TimeRemainingSecs = time_remaining_secs;
        end
    end
end