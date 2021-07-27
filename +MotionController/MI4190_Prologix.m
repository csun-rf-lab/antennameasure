classdef MI4190_Prologix < MotionController.MI4190
    %MI4190_PROLOGIX Class for controlling MI-4190 motion controller with
    %Prologix GPIB adapter.

    properties (SetAccess = protected, GetAccess = protected)
        % other props from parent class
        addr % GPIB address
        gpib % GPIBBus object
    end

    methods
        function obj = MI4190_Prologix(gpibbus, addr, axes, logger)
            obj = obj@MotionController.MI4190(axes, logger); % call superclass constructor

            try
                obj.addr = uint8(addr); % GPIB address is an integer
                obj.gpib = gpibbus;
                obj.setConnectedState(false);

                % Verify connection
                %fprintf(obj.sp, '*CLS'); % clear output/error queues
                obj.gpib.send(obj.addr, "*idn?");
                idn = obj.gpib.recv(100);
                obj.log.Info(sprintf("Position Controller ID: %s\n", idn));
                obj.setConnectedState(true);
            catch E
                disp(E);
                obj.log.Error("Error communicating with MI4190");
            end
        end

        function setGPIBAddress(obj, addr)
            obj.addr = addr;
            obj.log.Info(sprintf("Changed target GPIB address to %d", addr));
        end

        function addr = getGPIBAddress(obj)
            addr = obj.addr;
        end
    end % methods

    methods (Access = protected)
        function send(obj, msg)
            obj.log.Debug(sprintf("send(): %s", msg));
            obj.gpib.send(obj.addr, msg);
        end

        function msg = recv(obj, len)
            msg = obj.gpib.recv(len);
            obj.log.Debug(sprintf("recv(): %s", msg));
        end

        function data = fread(obj)
            % TODO: deal with buffer size
            data = obj.gpib.fread();
            obj.log.Debug(sprintf("fread(): %s", data));
        end
    end % protected methods
end