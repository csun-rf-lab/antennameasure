classdef Keysight_P937xA < VNA.AbstractVNA
    %Keysight_P937xA Class for controlling the USB VNA.

    properties (SetAccess = protected, GetAccess = protected)
        % log,  in superclass
        measurementParams
    end

    methods
        function obj = Keysight_P937xA(visabus, logger)
            obj.bus = visabus;
            obj.log = logger;
        end

        function init(obj)
            % INIT Initialize VNA for use

            % Preset
            obj.gpibSDC();
            obj.send("OPC?;PRES;");
            try
                maxInitWait = 10; % wait up to 10 seconds
                obj.waitOpc(maxInitWait);
            catch e
                msg = sprintf("Failed to initialize VNA after %d seconds", maxInitWait);
                obj.log.Error(msg);
                error("Keysight_P937xA::init(): %s", msg);
            end

            % We only record S21.
            obj.send("S21");

            % Set scale to 20 dB/div
            obj.send("SCAL 20");

            pause(1); % give it a moment to think
        end

        function beforeMeasurements(obj)
            % BEFOREMEASUREMENTS Prepare to take a set of measurements   

            % Read the start/stop frequencies and number of points from the VNA:
            obj.measurementParams.startFreq = obj.getStartFreq();
            obj.measurementParams.stopFreq = obj.getStopFreq();
            obj.measurementParams.numPoints = obj.getNumPts();

            % Set IF BW to something reasonable
            % If you get an error on the formula for ifbw (below),
            % comment that out and uncomment the hard-coded value.
            ifbw = 10;
            %ifbw = 1000 / (obj.measurementParams.stopFreq / 1e9);
            obj.send("IFBW " + num2str(ifbw));

            % Get remaining config from VNA
            obj.measurementParams.IFBW = obj.getIFBW();
            obj.measurementParams.sweepTime = obj.getSweepTime();
            obj.measurementParams.SCAL = obj.queryFreqParam("SCAL");
            obj.measurementParams.REFP = obj.queryFreqParam("REFP");
            obj.measurementParams.REFV = obj.queryFreqParam("REFV");

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
                start = obj.queryFreqParam("SENSe:FREQuency:STARt");
            catch e
                disp(e);
                obj.log.Error(e.message);
            end
        end

        function setStartFreq(obj, freq)
            % SETSTARTFREQ Set the start frequency for measurements
            try
                obj.setFreqParam("SENSe:FREQuency:STARt", freq);
                pause(1); % give it a moment to think
            catch e
                disp(e);
                obj.log.Error(e.message);
            end
        end

        function stop = getStopFreq(obj)
            % GETSTOPFREQ Get the stop frequency for measurements
            try
                stop = obj.queryFreqParam("SENSe:FREQuency:STOP");
                pause(1); % give it a moment to think
            catch e
                disp(e);
                obj.log.Error(e.message);
            end
        end

        function setStopFreq(obj, freq)
            % SETSTOPFREQ Set the stop frequency for measurements
            try
                obj.setFreqParam("SENSe:FREQuency:STOP", freq);
            catch e
                disp(e);
                obj.log.Error(e.message);
            end
        end

        function center = getCenterFreq(obj)
            % GETCENTERFREQ Get the center frequency for measurements
            try
                center = obj.queryFreqParam("SENSe:FREQuency:CENTer");
            catch e
                disp(e);
                obj.log.Error(e.message);
            end
        end

        function setCenterFreq(obj, freq)
            % SETCENTERFREQ Set the center frequency for measurements
            try
                obj.setFreqParam("SENSe:FREQuency:CENTer", freq);
            catch e
                disp(e);
                obj.log.Error(e.message);
            end
        end

        function span = getSpan(obj)
            % GETSPAN Get the span for measurements
            try
                span = obj.queryFreqParam("SENSe:FREQuency:SPAN");
            catch e
                disp(e);
                obj.log.Error(e.message);
            end
        end

        function setSpan(obj, span)
            % SETSPAN Set the span for measurements
            try
                obj.setFreqParam("SENSe:FREQuency:SPAN", span);
            catch e
                disp(e);
                obj.log.Error(e.message);
            end
        end

        function numPts = getNumPts(obj)
            % GETNUMPTS Get the number of data points to be collected in
            % measurements
            try
                numPts = obj.queryFreqParam("SENSe:SWEep:POINts");
            catch e
                disp(e);
                obj.log.Error(e.message);
            end
        end

        function setNumPts(obj, numPts)
            % SETNUMPTS Set the number of data points to be collected in measurements
            try
                obj.setNumParam("SENSe:SWEep:POINts", numPts);
            catch e
                disp(e);
                obj.log.Error(e.message);
            end
        end

        function ifbw = getIFBW(obj)
            try
                ifbw = obj.queryFreqParam("SENSe:BANDwidth");
            catch e
                disp(e);
                obj.log.Error(e.message);
            end
        end
        
        function setIFBW(obj, ifbw)
            try
                obj.setNumParam("SENSe:BANDwidth", ifbw);
            catch e
                disp(e);
                obj.log.Error(e.message);
            end
        end

        function time = getSweepTime(obj)
            try
                time = obj.queryFreqParam("SENSe:SWEep:TIME");
            catch e
                disp(e);
                obj.log.Error(e.message);
            end
        end

        function setSweepTime(obj, time)
            try
                obj.setNumParam("SENSe:SWEep:TIME", time);
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

            % Make the measurement and return the data
            maxAttempts = 3;
            for attempt = 1:maxAttempts
                try
                    S21 = obj.getMeasurementData(numPoints);
                    break; % on success, don't try again.
                catch e
                    disp(e);
                    obj.log.Error("Failed to obtain measurement data.");

                    if (attempt < maxAttempts)
                        obj.log.Error("Making another attempt...");
                    else
                        obj.log.Error("Max attempts reached.");
                        obj.setTimeout(timeout); % Restore timeout
                        error("Keysight_P937xA::measure(): Max measurement attempts reached");
                    end
                end
            end

            obj.log.Info("Done.");

            results.startFreq = obj.measurementParams.startFreq;
            results.stopFreq = obj.measurementParams.stopFreq;
            results.sweepTime = obj.measurementParams.sweepTime;
            results.SCAL = obj.measurementParams.SCAL;
            results.REFP = obj.measurementParams.REFP;
            results.REFV = obj.measurementParams.REFV;
            results.freq = freq;
            results.S21 = S21;

            try
                obj.onMeasurement(results); % Notify event handlers
            catch e
                disp(e);
            end

            obj.setTimeout(timeout);
        end % measure()
    end % methods

    methods (Access = protected)
        function S21 = getMeasurementData(obj, numPoints)
            % getMeasurementData is called from measure() to initiate a
            % single measurement and obtain the results from the VNA. It is
            % isolated here so that multiple attempts can be made, in the
            % event of a bus communications glitch.

            % Perform a single sweep and poll for completion
            obj.send("OPC?;SING;");
            try
                % Make sure we wait as long as our sweep should take
                maxWait = obj.measurementParams.sweepTime*1.1;
                % Poll for operation completion
                obj.waitOpc(maxWait);
            catch e
                msg = sprintf("Failed to complete measurement after %d seconds", maxWait);
                obj.log.Error(msg);
                error("Keysight_P937xA::getMeasurementData(): %s", msg);
            end

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
                error("Keysight_P937xA::getMeasurementData(): Received wrong number of data points: %d (expected %d)", length(S21), numPoints);
            end
        end

        function waitOpc(obj, maxWait)
            for iteration=0:maxWait
% TODO: Don't just assume read timeout is 1 second
                % For details about OPC? command, see programming manual
                % page 307 (2-15)
                opc = obj.recv(1);
                if (str2double(opc) == 1)
                    obj.recv(1); % clear a non-printable character from the buffer
                    break;
                end
                % Next iteration is about a second later, because this is
                % the read timeout for the serial operations.
            end

            if (str2double(opc) ~= 1)
                msg = sprintf("VNA operation failed to complete after %d seconds", maxWait);
                obj.log.Error(msg);
                error("Keysight_P937xA::waitOpc(): %s", msg);
            end
        end

        function send(obj, msg)
        end

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

        % Overridden in Prologix class
        function gpibSDC(obj)
        end
    end % protected methods
end
