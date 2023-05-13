classdef Keysight_P937xA < VNA.AbstractVNA
    %Keysight_P937xA Class for controlling the USB VNA.

    properties (SetAccess = protected, GetAccess = protected)
        % log,  in superclass
        measurementParams
        bus
    end

    methods
        function obj = Keysight_P937xA(visabus, logger)
            obj.bus = visabus;
            obj.log = logger;
        end

        function init(obj)
            % INIT Initialize VNA for use

            % Ident
            obj.send("*IDN?");
            id = obj.recv(100);
            obj.log.Info(sprintf("Keysight_P937xA::init(): Connected to %s", id));

            % Preset
            %obj.send("*OPC?;SYST:FPR"); % preset without creating a window/trace
            obj.send("*OPC?;SYST:PRES"); % Preset with a single window/trace showing S11
            try
                maxInitWait = 10; % wait up to 10 seconds
                obj.waitOpc(maxInitWait);
            catch e
                e
                msg = sprintf("Failed to initialize VNA after %d seconds", maxInitWait);
                obj.log.Error(msg);
                error("Keysight_P937xA::init(): %s", msg);
            end

            % We only record S21.
            obj.send("CALC1:MEAS1:PAR 'S21'");

            % Set a reasonable default power level.
            % (The P9374A seems to pick -5 dBm by default.)
            obj.setPower(-10);

            % Set scale to 20 dB/div
            obj.send("DISPlay:WINDow1:TRACe1:Y:SCALe:PDIVision 20");

            pause(1); % give it a moment to think
        end

        function conn = isConnected(obj)
            conn = obj.bus.isConnected();
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
            obj.setIFBW(ifbw);

            % Get remaining config from VNA
            obj.measurementParams.IFBW = obj.getIFBW();
            obj.measurementParams.sweepTime = obj.getSweepTime();
            obj.measurementParams.SCAL = obj.queryFreqParam("DISP:WIND:TRAC:Y:SCALe:PDIVision");
            obj.measurementParams.REFP = obj.queryFreqParam("DISP:WIND:TRAC:Y:RPOS");
            obj.measurementParams.REFV = obj.queryFreqParam("DISP:WIND:TRAC:Y:RLEV");

            % Make sure there's no junk in the buffer.
            obj.bus.recv(1000);
        end

        function afterMeasurements(obj)
            % AFTERMEASUREMENTS Wrap things up after taking a set of
            % measurements.

            % Set to sweep continuously
            obj.send("SENS:SWE:MODE CONT");
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
                %pause(1); % give it a moment to think
            catch e
                disp(e);
                obj.log.Error(e.message);
            end
        end

        function stop = getStopFreq(obj)
            % GETSTOPFREQ Get the stop frequency for measurements
            try
                stop = obj.queryFreqParam("SENSe:FREQuency:STOP");
                %pause(1); % give it a moment to think
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

        function pwr_dbm = getPower(obj)
            obj.send(sprintf('SOURCE:POW? "Port 1"'));
            pwr_dbm = obj.recv(40);
            pwr_dbm = str2num(pwr_dbm);
        end

        function setPower(obj, pwr_dbm)
            try
                obj.send(sprintf('SOURCE:POW %d, "Port 1"', pwr_dbm));
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
                obj.setNumParam("SENS:BWID", ifbw);
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

            timeout = obj.bus.getTimeout();

            % Compute the expected frequency points from the VNA.
            % Round to 100 kHz?
            freq = 1e5*round((startFreq:(stopFreq-startFreq)/(numPoints-1):stopFreq)/1e5);

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

            obj.bus.setTimeout(timeout);
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
            obj.send(sprintf("%s %dHZ;", param, value));
        end

        % value is just numerical
        function setNumParam(obj, param, value)
            obj.send(sprintf("%s %d;", param, value));
        end

        function S21 = getMeasurementData(obj, numPoints)
            % getMeasurementData is called from measure() to initiate a
            % single measurement and obtain the results from the VNA. It is
            % isolated here so that multiple attempts can be made, in the
            % event of a bus communications glitch.

            % Set mode properly
            obj.send("FORM REAL,64");
            obj.send("FORM:BORD SWAP"); % or NORM

            % Perform a single sweep and poll for completion
            obj.send("SENS:SWE:MODE SING;*OPC?");
            try
                % Make sure we wait as long as our sweep should take.
                % Note that this can be very wrong if a calibration is
                % being applied (particularly with more than one port
                % calibrated).
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
            obj.send("CALC:MEAS1:DATA:SDATA?"); % read s-param data in complex format

            S21 = obj.bus.fread_binary(numPoints);

            % Sanity check
            if length(S21) ~= numPoints
                error("Keysight_P937xA::getMeasurementData(): Received wrong number of data points: %d (expected %d)", length(S21), numPoints);
            end
        end

        function waitOpc(obj, maxWait)
            t = obj.bus.getTimeout();
            obj.bus.setTimeout(1);
            for iteration=0:maxWait
                opc = obj.recv(1);
                if (str2double(opc) == 1)
                    obj.recv(1); % clear a non-printable character from the buffer
                    break;
                end
                % Next iteration is about a second later, because this is
                % the read timeout.
            end
            obj.bus.setTimeout(t);

            if (str2double(opc) ~= 1)
                msg = sprintf("VNA operation failed to complete after %d seconds", maxWait);
                obj.log.Error(msg);
                error("Keysight_P937xA::waitOpc(): %s", msg);
            end
        end

        function send(obj, msg)
            recipient_addr = 0; % ignored for VISA bus
            obj.bus.send(recipient_addr, msg);
        end

        function msg = recv(obj, len)
            msg = obj.bus.recv(len);
        end
    end % protected methods
end
