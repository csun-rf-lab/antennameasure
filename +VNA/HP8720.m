classdef HP8720 < VNA.AbstractVNA
    %HP8720 Class for controlling the HP8720 VNA.
    %   This class must be provided a serialport object in the constructor,
    %   and can be used to control any number of axes on the controller.

    properties (SetAccess = protected, GetAccess = protected)
        % log,  in superclass
        dataXferMethod
        measurementParams
    end

    methods
        function obj = HP8720(logger)
            %HP8720 Construct an instance of this class
            obj.log = logger;

            % FORM5 is binary and is much faster for large data transfers.
            % FORM4 is ASCII and much slower for large data transfers,
            %       but has lower overhead for small data transfers.
            obj.dataXferMethod = "FORM5";
        end

        function init(obj)
            % INIT Initialize VNA for use

            % Preset
            obj.send("PRES");

            % Set to sweep continuously
            obj.send("CONT");
        end

        function beforeMeasurements(obj)
            % BEFOREMEASUREMENTS Prepare to take a set of measurements

            % Read the start/stop frequencies and number of points from the VNA:
            obj.measurementParams.startFreq = obj.getStartFreq();
            obj.measurementParams.stopFreq = obj.getStopFreq();
            obj.measurementParams.numPoints = obj.getNumPts();

            obj.measurementParams.SCAL = obj.queryFreqParam("SCAL");
            obj.measurementParams.REFP = obj.queryFreqParam("REFP");
            obj.measurementParams.REFV = obj.queryFreqParam("REFV");

            % We only record S21.
            % Once set, we pause for a moment so the VNA can catch up.
            obj.send("S21");
            pause(2);

            % Set the output data format
            obj.send(obj.dataXferMethod);

            % Make sure there's no junk in the buffer.
            obj.fread();
        end

        function afterMeasurements(obj)
            % AFTERMEASUREMENTS Wrap things up after taking a set of
            % measurements.

            % Set to sweep continuously
            obj.send("CONT");
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
            catch e
                disp(e);
                obj.log.Error(e.message);
            end
        end

        function stop = getStopFreq(obj)
            % GETSTOPFREQ Get the stop frequency for measurements
            try
                stop = obj.queryFreqParam("STOP");
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

        function results = measure(obj)
            % MEASURE Return measurement results

            startFreq = obj.measurementParams.startFreq;
            stopFreq = obj.measurementParams.stopFreq;
            numPoints = obj.measurementParams.numPoints;

            timeout = obj.getTimeout();
%            try
                % Compute the expected frequency points from the VNA. The 8720B has a 100
                % KHz frequency resolution, so round to this.
                freq = 1e5*round((startFreq:(stopFreq-startFreq)/(numPoints-1):stopFreq)/1e5);

                % Increase the timeout to give enough time for data transfer
                % This is based on the number of points set on the VNA
                if obj.dataXferMethod == "FORM5"
                    % 1 second works for FORM5,
                    % even for the max number of data points.
                    obj.setTimeout(1);
                else
                    % FORM4
                    % The following emperical formula is approximate.
                    obj.setTimeout(ceil(numPoints/100*0.5));
                end

                % Perform a single sweep and pause to give time for a single sweep to
                % complete. This may need to be adjusted based on the frequency span,
                % number of points, IF bandwidth, and averaging
                obj.send("SING");
% TODO: Can we poll to see when the operation completes?
% Yes? Use OPC command.  But couldn't get it working?

                % Output the data
                obj.log.Info("Transferring S21 data...");
                obj.send("OUTPDATA");

                if obj.dataXferMethod == "FORM4"
                    dataTran = obj.fread();
                    % Convert character data to numbers
                    dataNums = textscan(dataTran,'%f%f','Delimiter',',');
                    S21 = dataNums{1} + j*dataNums{2};
                else % FORM5
                    dataTran = obj.fread_FORM5(numPoints);
                    S21 = dataTran(1:2:end) + j*dataTran(2:2:end);
                end

                % Sanity check
                if length(S21) ~= numPoints
                    error("HP8720::measure(): Received wrong number of data points: %d", length(S21));
                end

                obj.log.Info("Done.");

                results.startFreq = obj.measurementParams.startFreq;
                results.stopFreq = obj.measurementParams.stopFreq;
                results.SCAL = obj.measurementParams.SCAL;
                results.REFP = obj.measurementParams.REFP;
                results.REFV = obj.measurementParams.REFV;
                results.freq = freq;
                results.S21 = S21;
%             catch e
%                 disp(e);
%                 obj.log.Error(e.message);
%             end % try/catch

            obj.setTimeout(timeout);
        end % measure()
    end % methods

    methods (Access = protected)
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

        % Overridden in Prologix class
        function send(obj, msg)
        end

        % Overridden in Prologix class
        function msg = recv(obj, len)
        end

        % Overridden in Prologix class
        function data = fread(obj)
        end

        % Overridden in Prologix class
        function data = fread_FORM5(obj, numDataPoints)
        end

        % Overridden in Prologix class
        function t = getTimeout(obj)
        end

        % Overridden in Prologix class
        function setTimeout(obj, timeout)
        end
    end % protected methods
end
