classdef Dummy < VNA.AbstractVNA

    properties (SetAccess = protected, GetAccess = protected)
        % log,  in superclass
        start
        stop
        center
        span
        numPts
    end

    methods
        function obj = Dummy(logger)
            %DUMMY Construct an instance of this class
            obj.log = logger;

        end

        function init(obj)
            % INIT Initialize VNA for use
            % Nothing to do here in dummy
        end

        function beforeMeasurements(obj)
            % BEFOREMEASUREMENTS Prepare to take a set of measurements
            % Nothing to do here in dummy
        end

        function afterMeasurements(obj)
            % AFTERMEASUREMENTS Wrap things up after taking a set of
            % measurements.
            % Nothing to do here in dummy
        end

        function start = getStartFreq(obj)
            % GETSTARTFREQ Get the start frequency for measurements
            start = obj.start;
        end

        function setStartFreq(obj, freq)
            % SETSTARTFREQ Set the start frequency for measurements
            obj.start = freq;
        end

        function stop = getStopFreq(obj)
            % GETSTOPFREQ Get the stop frequency for measurements
            stop = obj.stop;
        end

        function setStopFreq(obj, freq)
            % SETSTOPFREQ Set the stop frequency for measurements
            obj.stop = freq;
        end

        function center = getCenterFreq(obj)
            % GETCENTERFREQ Get the center frequency for measurements
            center = obj.center;
        end

        function setCenterFreq(obj, freq)
            % SETCENTERFREQ Set the center frequency for measurements
            obj.center = freq;
        end

        function span = getSpan(obj)
            % GETSPAN Get the span for measurements
            span = obj.span;
        end

        function setSpan(obj, span)
            % SETSPAN Set the span for measurements
            obj.span = span;
        end

        function numPts = getNumPts(obj)
            % GETNUMPTS Get the number of data points to be collected in
            % measurements
            numPts = obj.numPts;
        end

        function setNumPts(obj, numPts)
            % SETNUMPTS Set the number of data points to be collected in measurements
            obj.numPts = numPts;
        end

        function results = measure(obj)
            % MEASURE Return measurement results
% TODO: Generate some realistic dummy data
            startFreq = obj.start;
            stopFreq = obj.stop;
            numPoints = obj.numPts;

            % Load some data to return
            load("results.mat", "results");

            obj.onMeasurement(results);

            % results is returned
        end % measure()
    end % methods
end