classdef PrologixUsb < GPIBBus.AbstractGPIBBus
    %PROLOGIXUSB Class for communicating on a GPIB bus using a Prologix USB
    %adapter.
    
    properties (SetAccess = protected, GetAccess = protected)
        % other props from parent class
        addr    % gpib address to speak to (keeps track of most recent)
        comport % serial port string
        sp      % serial port object
    end

    methods
        function obj = PrologixUsb(comport, logger)
            assert(isstring(comport) || (ischar(comport) && length(comport) > 1), "comport must be a string.");

            obj.log = logger;

            obj.comport = comport;
            obj.setConnectedState(false);

            obj.addr = -1; % This will be changed when we try to send a msg
            obj.connect();
        end

        function setTimeout(obj, t)
            obj.sp.Timeout = t;
        end

        function t = getTimeout(obj)
            t = obj.sp.Timeout;
        end

        function connect(obj)
            obj.log.Info(sprintf('connect() %s\n', obj.comport));
            if ~isempty(instrfind) % Clean up if port is already open
                fclose(instrfind);
                delete(instrfind);
            end

            % per Prologix manual, baudrate can be set to anything.
            baudrate = 9600;

            try
                %sp = serialport(obj.comport, baudrate, "Timeout", "0.5");
                sp = serial(obj.comport);

                % We found by trial and luck that both the MI4190 and
                % HP87XX were happy to communicate with LF as the terminator.
                %sp.configureTerminator('LF');
                sp.Terminator = 'LF';

                % Reduce the timeout from the default 10 seconds to speed things up
                sp.Timeout = 0.5;

                % Set input buffer to be large enough for trace data to be transferred
                % The largest data set is 1601 points and this requires about 100 kB
                sp.InputBufferSize = 100000;

                fclose(sp);
                fopen(sp);
                obj.sp = sp;
                obj.setConnectedState(true);
% TODO: Is this pause necessary?
                pause(1);

                % Configure as Controller (++mode 1), instrument address #,
                % and with read-after-write (++auto 1) enabled.
                % eoi and eos set line endings properly.
                fprintf(obj.sp, "++mode 1");
                fprintf(obj.sp, "++auto 1");
                fprintf(obj.sp, "++eoi 1");
                fprintf(obj.sp, '++eos 2');

% TODO: how to detect that something went wrong?
            catch E
                disp(E)
                obj.log.Error("Failed to open serial port");
                %error("GPIBBus.PrologixUsb:serialport:ConnectionFailed", "Could not open serial port");
                obj.setConnectedState(false);
            end
        end

        function disconnect(obj)
            if obj.connected
                fclose(obj.sp);
                obj.setConnectedState(false);
            end
        end

        function setSerialPort(obj, comport)
            obj.comport = comport;
            obj.log.Info(sprintf("Changed target serial port to %s", obj.comport));
            obj.disconnect();
        end

        function comport = getSerialPort(obj)
            comport = obj.comport;
        end

        function send(obj, recipientAddr, msg)
            obj.setGPIBAddress(uint8(recipientAddr));

            obj.log.Debug(sprintf("send(): %s", msg));
            fprintf(obj.sp, msg);
            % with serialport() this would be writeline()
        end

        function msg = recv(obj, len)
            msg = char(fread(obj.sp, len))';
%            % TODO: MATLAB suggests this instead (I think):
%            %msg = fread(obj.sp, len, '*char')';
            % Better yet: use readline() with the newer serialport() model.

            % messages seem to have trailing newlines
            msg = strtrim(msg);
            % May need to do something like this:
            % strtrim(sprintf('0   \n'))
            % because matlab is picky.

            obj.log.Debug(sprintf("recv(): %s", msg));
        end

        function data = fread(obj)
            data = char(fread(obj.sp, 100000))';
            obj.log.Debug(sprintf("fread(): %s", data));
        end

        function data = fread_FORM5(obj, numDataPoints)
            % FREAD_FORM5 Read FORM5 data from the HP VNA.

            data = fread(obj.sp, 2); % "#A"
            % TODO: Check that we did in fact receive "#A"
            ct = fread(obj.sp, 2); % # Number of expected bytes
            % TODO: Convert ct and check that we get the expected number of
            % bytes in the result.
            data = fread(obj.sp, numDataPoints*2*4, "float32");
            obj.log.Debug(sprintf("fread(): %s", data));
        end

        function sdc(obj, recipientAddr)
            obj.log.Debug(sprintf("SDC"));
            obj.setGPIBAddress(uint8(recipientAddr));
            fprintf(obj.sp, "++clr");
        end
    end % methods

    methods (Access = protected)
        function setGPIBAddress(obj, addr)
            obj.log.Debug(sprintf("TRYING TO SET ADDRESS %d (currently %d)", addr, obj.addr));
           if addr ~= obj.addr
                obj.addr = addr;
                if obj.connected
                    fprintf(obj.sp, sprintf("++addr %d", addr));
                end
                obj.log.Info(sprintf("Changed target GPIB address to %d", addr));
            end
        end
    end % protected methods
end
