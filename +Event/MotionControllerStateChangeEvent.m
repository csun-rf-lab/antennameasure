classdef (ConstructOnLoad) MotionControllerStateChangeEvent < event.EventData
    properties
        Axis = 0
        Moving = false
        Fault = false
        Position = 0
    end

    methods
        % This all seems pretty strange, but I based this on:
        % https://www.mathworks.com/help/matlab/matlab_oop/class-with-custom-event-data.html
        % I had to modify things a bit to actually work here.
        % AbstractMotionController has an instance of
        % MotionControllerStateChangeContainer, which is able to emit
        % events. Consuming code gets the event container from
        % AbstractMotionController and adds a listener. When events occur,
        % AbstractMotionController calls
        % MotionControllerStateChangeContainer::onStateChange(), which in
        % turns creates a MotionControllerStateChangeEvent object, which is
        % emitted and then received by the consuming code.
        % Yeah, I know it's confusing. Maybe there's a better way of doing
        % events in matlab? But this is the best I could come up with based
        % on their documentation and the fact that AbstractMotionController
        % is, well, abstract.
        function eventData = MotionControllerStateChangeEvent(state)
            eventData.Axis = state.axis;
            eventData.Moving = state.moving;
            eventData.Fault = state.fault;
            eventData.Position = state.position;
        end
    end
end