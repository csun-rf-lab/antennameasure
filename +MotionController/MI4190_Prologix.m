classdef MI4190_Prologix < MotionController.MI4190
    %MI4190_PROLOGIX Class for controlling MI-4190 motion controller with
    %Prologix GPIB adapter.
    %   This class wraps the MI4190 driver and initalizes the Prologix
    %   device.

    properties (SetAccess = protected, GetAccess = protected)
        % other props from parent class
        addr    % GPIB address
        comport % serial port string
        sp      % serial port object
    end

    methods
        function obj = MI4190_Prologix(comport, addr, axes, logger)
            assert(isstring(comport) || (ischar(comport) && length(comport) > 1), "comport must be a string.");

            obj = obj@MotionController.MI4190(axes, logger); % call superclass constructor

            obj.addr = uint8(addr); % GPIB address is an integer
            obj.comport = comport;
            obj.setConnectedState(false);

            obj.connect();
        end

        function connect(obj)
            obj.log.Info(sprintf('connect() %s GPIB#%d\n', obj.comport, obj.addr));
if ~isempty(instrfind)
    fclose(instrfind)
    delete(instrfind)
end

            % per Prologix manual, baudrate can be set to anything.
            baudrate = 9600;

            try
                %sp = serialport(obj.comport, baudrate, "Timeout", "0.5");
                sp = serial(obj.comport);

%TODO: Update this comment. It seems wrong now, after 2021-06-17 in the
%lab.
                % Prologix Controller 4.2 requires CR as command terminator, LF is
                % optional. The controller terminates internal query responses with CR and
                % LF. Responses from the instrument are passed through as is. (See Prologix
                % Controller Manual)
                %sp.configureTerminator('LF');
                sp.Terminator = 'LF';

                % Reduce the timeout from the default 10 seconds to speed things up
                sp.Timeout = 0.5;

                fclose(sp);
                fopen(sp);
                obj.sp = sp;
                obj.setConnectedState(true);

                pause(1);

                % Configure as Controller (++mode 1), instrument address #,
                % and with read-after-write (++auto 1) enabled.
                % eoi and eos set line endings properly.
                fprintf(obj.sp, '++mode 1');
                fprintf(obj.sp, sprintf('++addr %d', obj.addr));
                fprintf(obj.sp, '++auto 1');
                fprintf(obj.sp, '++eoi 1');
                fprintf(obj.sp, '++eos 2'); % works with 2 or 3

                % Verify connection
                %fprintf(obj.sp, '*CLS'); % clear output/error queues
                fprintf(obj.sp, '*idn?');
                idn = obj.recv(100);
                obj.log.Info(sprintf('Position Controller ID: %s\n', idn));

% TODO: how to detect that something went wrong?
            catch E
                disp(E)
                obj.log.Error("Failed to open serial port");
                %error("MI4190_Prologix:serialport:ConnectionFailed", "Could not open serial port");
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

        function setGPIBAddress(obj, addr)
            obj.addr = addr;
            if obj.connected
                fprintf(obj.sp, '++addr %d', addr);
            end
            obj.log.Info(sprintf("Changed target GPIB address to %d", addr));
        end

        function addr = getGPIBAddress(obj)
            addr = obj.addr;
        end

        % TODO: This should probably be protected
        function send(obj, msg)
            obj.log.Debug(sprintf("send(): %s", msg));
            fprintf(obj.sp, msg);
            % with serialport() this would be writeline()
        end

        % TODO: This too
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
    end
end