classdef AbstractVNA< handle
    %ABSTRACTVNA Base class

    properties (SetAccess = protected, GetAccess = protected)
        connected = false % bool: connected to VNA?
        ec   % Container for emitting events
        log  % Logger object
        onConnectStateChangeCb
    end

    methods (Abstract)
        init(obj)
        % Initialize VNA for use

        beforeMeasurements(obj)
        % Prepare to take a set of measurements

        afterMeasurements(obj)
        % Wrap things up after taking a set of measurements

        getStartFreq(obj)
        % Get the start frequency for measurements

        setStartFreq(obj, freq)
        % Set the start frequency for measurements

        getStopFreq(obj)
        % Get the stop frequency for measurements

        setStopFreq(obj, freq)
        % Set the stop frequency for measurements

        getCenterFreq(obj)
        % Return the center frequency for measurements

        setCenterFreq(obj, freq)
        % Set the center frequency for measurements

        getSpan(obj)
        % Return the span for measurements

        setSpan(obj, span)
        % Set the span for measurements

        getNumPts(obj)
        % Return the number of data points to be collected in measurements

        setNumPts(obj, numPts)
        % Set the number of data points to be collected in measurements

        measure(obj)
        % Return measurement results
    end

    methods
        function obj = AbstractVNA()
            obj.ec = Event.VNAMeasurementEventContainer;
        end

        function ec = getEventContainer(obj)
            ec = obj.ec;
        end

         function conn = isConnected(obj)
             conn = obj.connected;
         end

        function setOnConnectStateChangeCallback(obj, cb)
            obj.onConnectStateChangeCb = cb;
        end

        function clearOnConnectStateChangeCallback(obj)
            clear obj.onConnectStateChangeCb;
        end
    end

    methods (Access = protected)
        function onMeasurement(obj, results)
            % onMeasurement called by extending class when a measurement
            % occurs. This method collects the relevant information and
            % calls the measurement callback.

            % I couldn't figure out a sane way to emit events from here,
            % so we go through this other class:
            obj.ec.onMeasurement(results);
        end

        function setConnectedState(obj, state)
            obj.connected = state;
            if isa(obj.onConnectStateChangeCb, 'function_handle')
                obj.onConnectStateChangeCb(obj.connected);
            end
        end
    end
end