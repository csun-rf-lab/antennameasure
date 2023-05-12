classdef VISA < GPIBBus.AbstractGPIBBus
    %VISA Class for communicating with instruments via VISA hosted by
    %the Keysight IO driver.
    
    properties (SetAccess = protected, GetAccess = protected)
        % other props from parent class
        addr    % visa address to speak to (keeps track of most recent)
        visa    % visa object
    end

    methods
        function obj = VISA(addr, logger)
            assert(isstring(addr) || (ischar(addr) && length(addr) > 1), "addr must be a string.");

            obj.log = logger;

            obj.addr = addr;
            obj.setConnectedState(false);

            obj.connect();
            obj.setTimeout(0.5); % 1/2 second is plenty fast for most operations
        end

        function setTimeout(obj, t)
            obj.visa.Timeout = t;
        end

        function t = getTimeout(obj)
            t = obj.visa.Timeout;
        end

        function connect(obj)
            obj.log.Info(sprintf('connect() %s\n', obj.addr));

            try
                obj.visa = visadev(obj.addr);
                obj.setConnectedState(true);
% TODO: how to detect that something went wrong?
            catch E
                disp(E)
                obj.log.Error("Failed to open visa connection");
                %error("GPIBBus.PrologixUsb:serialport:ConnectionFailed", "Could not open visa connection");
                obj.setConnectedState(false);
            end
        end

        function disconnect(obj)
            if obj.connected
                clear obj.visa
                obj.setConnectedState(false);
            end
        end

        function v = getVisaObj(obj)
            v = obj.visa;
        end

        function send(obj, recipientAddr, msg)
            obj.log.Debug(sprintf("send(): %s", msg));
            writeline(obj.visa, msg);
        end

        function msg = recv(obj, len)
            %msg = char(read(obj.visa, len))';
            msg = char(read(obj.visa, len));

            % messages seem to have trailing newlines
            msg = strtrim(msg);

            obj.log.Debug(sprintf("recv(): %s", msg));
        end

        function data = fread()
            % unused here
        end

        function data = fread_binary(obj, num_pts)
            % read binary data
            obj.log.Debug("Entered fread() function");

            % First is an ascii hash sign followed by a single digit
            % representing the number of bytes telling the total size
            % of the data transmitted
            prefix = char(read(obj.visa, 2)); % like #4
            if prefix(1) ~= '#'
                error("Unexpected prefix");
            end
            hdrsize = str2num(prefix(2)); % number of bytes remaining in header
            datasize = str2num(char(read(obj.visa, hdrsize)));

            % Expected number of bytes:
            %   Number of points
            %       x
            %   2 (real and imaginary for each point)
            %       x
            %   8 (8 bytes in a 64-bit/double number)
            expected_data_size = num_pts * 2 * 8;
            if datasize ~= expected_data_size
                error("Data does not match expected data size");
            end
            data = read(obj.visa, datasize/8, "double");

            real = data(1:2:end);
            imag = data(2:2:end);
            data = real + j*imag;
            %obj.log.Debug(sprintf("fread(): %s", data));
        end

%         function data = fread_FORM5(obj, numDataPoints)
%             % FREAD_FORM5 Read FORM5 data from the HP VNA.
% 
%             data = fread(obj.sp, 2); % "#A"
%             % TODO: Check that we did in fact receive "#A"
%             ct = fread(obj.sp, 2); % # Number of expected bytes
%             % TODO: Convert ct and check that we get the expected number of
%             % bytes in the result.
%             data = fread(obj.sp, numDataPoints*2*4, "float32");
%             obj.log.Debug(sprintf("fread(): %s", data));
%         end

        function sdc(obj, recipientAddr)
            % Required for class to not be abstract, but not needed for
            % VISA. Should refactor superclass so this isn't necessary.
        end
    end % methods
end
