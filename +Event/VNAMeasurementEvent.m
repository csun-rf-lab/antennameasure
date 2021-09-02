classdef (ConstructOnLoad) VNAMeasurementEvent < event.EventData
    properties
        Results
    end

    methods
        function eventData = VNAMeasurementEvent(results)
            eventData.Results = results;
        end
    end
end