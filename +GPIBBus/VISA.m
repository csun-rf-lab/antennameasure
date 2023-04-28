classdef VISA < GPIBBus.AbstractGPIBBus
    %VISA Class for communicating with instruments via VISA hosted by
    %the Keysight IO driver.
    
    properties (SetAccess = protected, GetAccess = protected)
        % other props from parent class
        addr    % visa address to speak to (keeps track of most recent)
        visa    % visa object
    end

    methods
        function obj = PrologixUsb(addr, logger)
            assert(isstring(addr) || (ischar(addr) && length(addr) > 1), "addr must be a string.");

            obj.log = logger;

            obj.addr = addr;
            obj.setConnectedState(false);

            obj.connect();
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
            msg = char(read(obj.visa, len))';

%             % messages seem to have trailing newlines
%             msg = strtrim(msg);

            obj.log.Debug(sprintf("recv(): %s", msg));
        end

%         function data = fread(obj)
%             data = char(fread(obj.sp, 100000))';
%             obj.log.Debug(sprintf("fread(): %s", data));
%         end

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

%         function sdc(obj, recipientAddr)
%             obj.log.Debug(sprintf("SDC"));
%             obj.setGPIBAddress(uint8(recipientAddr));
%             fprintf(obj.sp, "++clr");
%         end
    end % methods

    methods (Access = protected)
%         function setGPIBAddress(obj, addr)
%             obj.log.Debug(sprintf("TRYING TO SET ADDRESS %d (currently %d)", addr, obj.addr));
%            if addr ~= obj.addr
%                 obj.addr = addr;
%                 if obj.connected
%                     fprintf(obj.sp, sprintf("++addr %d", addr));
%                 end
%                 obj.log.Info(sprintf("Changed target GPIB address to %d", addr));
%             end
%         end
    end % protected methods
end
