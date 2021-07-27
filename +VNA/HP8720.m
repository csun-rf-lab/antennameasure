classdef HP8720 < VNA.AbstractVNA
    %HP8720 Class for controlling the HP8720 VNA.
    %   This class must be provided a serialport object in the constructor,
    %   and can be used to control any number of axes on the controller.

    properties
        % log,  in superclass
    end

    methods
        function obj = HP8720(logger)
            %HP8720 Construct an instance of this class
            obj.log = logger;
        end

% TODO: Delete after initial testing
        function resp = TEST_COMM(obj, msg, respLen)
            obj.send(msg);
            resp = obj.recv(respLen);
        end

        function init(obj)
            % INIT Initialize VNA for use

            % Preset
            obj.send("PRES");

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

            timeout = obj.gpib.getTimeout();
            try
                % Read the start/stop frequencies and number of points from the VNA:
                startFreq = obj.getStartFreq();
                stopFreq = obj.getStopFreq();
                numPoints = obj.getNumPts();

                SCAL = obj.queryFreqParam("SCAL");
                REFP = obj.queryFreqParam("REFP");
                REFV = obj.queryFreqParam("REFV");

                % Compute the expected frequency points from the VNA. The 8720B has a 100
                % KHz frequency resolution, so round to this.
numPoints
                freq = 1e5*round((startFreq:(stopFreq-startFreq)/(numPoints-1):stopFreq)/1e5);

                % Set the output data format
                obj.send("FORM4");

                % Increase the timeout to give enough time for data transfer
                % This is based on the number of points set on the VNA
                % The following emperical formula is approximate
                obj.gpib.setTimeout(ceil(numPoints/100*0.5));

% TODO: Do we record all of the S-params for what we're doing?
                % Save each of the S-parameters
                %Snames = ['S11';'S12';'S21';'S22'];
                Snames = ['S21'];

                for n = 1:1 %%% WTF MATLAB
                    obj.send(Snames(n,:));

                    % Perform a single sweep and pause to give time for a single sweep to 
                    % complete. This may need to be adjusted based on the frequency span, 
                    % number of points, IF bandwidth, and averaging
                    obj.send("SING");
% TODO: Can we poll to see when the operation completes?
% Yes? Use OPC command.  But couldn't get it working?
                    pause(2);

                    % Output the data
                    obj.log.Info(sprintf("Transferring %s...", Snames(n,:)));
                    obj.send("OUTPDATA");

                    %dataTran = char(fread(obj.sp))';
                    dataTran = obj.fread();
                    obj.log.Info("Done.");

                    % Convert character data to numbers
                    dataNums = textscan(dataTran,'%f%f','Delimiter',',');

                    S(:,n) = dataNums{1} + j*dataNums{2};

                    % Sanity check
                    if length(S(:,n)) ~= numPoints
                        error("HP8720::measure(): Received wrong number of data points: %d", length(S(:,n)));
                    end
                end

                results.startFreq = startFreq;
                results.stopFreq = stopFreq;
                results.SCAL = SCAL;
                results.REFP = REFP;
                results.REFV = REFV;
                results.freq = freq;
                results.S = S;

                % Set to sweep continuously
                obj.send("CONT");
            catch e
                disp(e);
                obj.log.Error(e.message);
            end % try/catch

            obj.gpib.setTimeout(timeout);
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
    end % protected methods
end
