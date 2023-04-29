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

        measure(obj)
        % Return measurement results

        % protected methods

        % Matlab is complaining about these methods not being public in the
        % Keysight Vna class. It doesn't have a problem with it for the HP
        % class, though, so I'm just going to comment it out here for now.
        %send(obj, msg)
        %recv(obj, len) % returns a string
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

        function start = getStartFreq(obj)
            % GETSTARTFREQ Get the start frequency for measurements
            try
                start = obj.queryFreqParam("STAR");
            catch e
                disp(e);
                obj.log.Error(e.message);
            end
        end

        function setStartFreq(obj, freq)
            % SETSTARTFREQ Set the start frequency for measurements
            try
                obj.setFreqParam("STAR", freq);
                pause(1); % give it a moment to think
            catch e
                disp(e);
                obj.log.Error(e.message);
            end
        end

        function stop = getStopFreq(obj)
            % GETSTOPFREQ Get the stop frequency for measurements
            try
                stop = obj.queryFreqParam("STOP");
                pause(1); % give it a moment to think
            catch e
                disp(e);
                obj.log.Error(e.message);
            end
        end

        function setStopFreq(obj, freq)
            % SETSTOPFREQ Set the stop frequency for measurements
            try
                obj.setFreqParam("STOP", freq);
            catch e
                disp(e);
                obj.log.Error(e.message);
            end
        end

        function center = getCenterFreq(obj)
            % GETCENTERFREQ Get the center frequency for measurements
            try
                center = obj.queryFreqParam("CENT");
            catch e
                disp(e);
                obj.log.Error(e.message);
            end
        end

        function setCenterFreq(obj, freq)
            % SETCENTERFREQ Set the center frequency for measurements
            try
                obj.setFreqParam("CENT", freq);
            catch e
                disp(e);
                obj.log.Error(e.message);
            end
        end

        function span = getSpan(obj)
            % GETSPAN Get the span for measurements
            try
                span = obj.queryFreqParam("SPAN");
            catch e
                disp(e);
                obj.log.Error(e.message);
            end
        end

        function setSpan(obj, span)
            % SETSPAN Set the span for measurements
            try
                obj.setFreqParam("SPAN", span);
            catch e
                disp(e);
                obj.log.Error(e.message);
            end
        end

        function numPts = getNumPts(obj)
            % GETNUMPTS Get the number of data points to be collected in
            % measurements
            try
                numPts = obj.queryFreqParam("POIN");
            catch e
                disp(e);
                obj.log.Error(e.message);
            end
        end

        function setNumPts(obj, numPts)
            % SETNUMPTS Set the number of data points to be collected in measurements
            try
                obj.setNumParam("POIN", numPts);
            catch e
                disp(e);
                obj.log.Error(e.message);
            end
        end

        function ifbw = getIFBW(obj)
            try
                ifbw = obj.queryFreqParam("IFBW");
            catch e
                disp(e);
                obj.log.Error(e.message);
            end
        end
        
        function setIFBW(obj, ifbw)
            try
                obj.setNumParam("IFBW", ifbw);
            catch e
                disp(e);
                obj.log.Error(e.message);
            end
        end

        function time = getSweepTime(obj)
            try
                time = obj.queryFreqParam("SWET");
            catch e
                disp(e);
                obj.log.Error(e.message);
            end
        end

        function setSweepTime(obj, time)
            try
                obj.setNumParam("SWET", time);
            catch e
                disp(e);
                obj.log.Error(e.message);
            end
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

        function hz = queryFreqParam(obj, param)
            obj.send(sprintf("%s?", param));
            hz = obj.recv(40);
            hz = str2num(hz);
        end

        % value is in hz
        function setFreqParam(obj, param, value)
            obj.send(sprintf("%s%dHZ;", param, value));
        end

        % value is just numerical
        function setNumParam(obj, param, value)
            obj.send(sprintf("%s%d;", param, value));
        end
    end
end