classdef AbstractVNA< handle
    %ABSTRACTVNA Base class

    properties (SetAccess = protected, GetAccess = protected)
        connected = false % bool: connected to VNA?
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
        function setConnectedState(obj, state)
            obj.connected = state;
            if isa(obj.onConnectStateChangeCb, 'function_handle')
                obj.onConnectStateChangeCb(obj.connected);
            end
        end
    end
end