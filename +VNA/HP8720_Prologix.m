classdef HP8720_Prologix < VNA.HP8720
    %HP8720_PROLOGIX Class for controlling HP8720 VNA with Prologix USB
    %adapter.
    
    properties (SetAccess = protected, GetAccess = protected)
        % other props from parent class
        addr % GPIB address
        gpib % GPIBBus object
    end

    methods
        function obj = HP8720_Prologix(gpibbus, addr, logger)
            obj = obj@VNA.HP8720(logger); % call superclass constructor

            try
                obj.addr = uint8(addr); % GPIB address is an integer
                obj.gpib = gpibbus;
                obj.setConnectedState(false);

                % Verify connection
                obj.gpib.send(obj.addr, "*idn?");
                idn = obj.gpib.recv(100);
                obj.log.Info(sprintf("HP8720 VNA ID: %s\n", idn));
                obj.setConnectedState(true);
            catch E
                disp(E);
                obj.log.Error("Error communicating with HP8720");
            end
        end

        function setGPIBAddress(obj, addr)
            obj.addr = addr;
            obj.log.Info(sprintf("Changed target GPIB address to %d", addr));
        end

        function addr = getGPIBAddress(obj)
            addr = obj.addr;
        end
    end

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
            % TODO: deal with buffer size, particularly for the VNA.
            data = obj.gpib.fread();
            obj.log.Debug(sprintf("fread(): %s", data));
        end

        function data = fread_FORM5(obj, numDataPoints)
            data = obj.gpib.fread_special(numDataPoints);
            obj.log.Debug(sprintf("fread(): %s", data));
        end

        function t = getTimeout(obj)
            t = obj.gpib.getTimeout();
        end

        function setTimeout(obj, timeout)
            obj.gpib.setTimeout(timeout);
        end
    end % protected methods
end

