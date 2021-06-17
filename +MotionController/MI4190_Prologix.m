classdef MI4190_Prologix < MotionController.MI4190
    %MI4190_PROLOGIX Class for controlling MI-4190 motion controller with
    %Prologix GPIB adapter.
    %   This class wraps the MI4190 driver and initalizes the Prologix
    %   device.

    properties (SetAccess = protected, GetAccess = protected)
        % other props from parent class
        addr % GPIB address
    end

    methods
        function obj = MI4190_Prologix(comport, addr, axes, logger)
            assert(isstring(comport) || (ischar(comport) && length(comport) > 1), "comport must be a string.");
            addr = uint8(addr); % GPIB address is an integer

            % per Prologix manual, baudrate can be set to anything.
            baudrate = 9600;

            try
                sp = serialport(comport, baudrate);
            catch E
                disp(E)
                error("MI4190_Prologix:serialport:ConnectionFailed", "Could not open serial port");
            end

            % Prologix Controller 4.2 requires CR as command terminator, LF is
            % optional. The controller terminates internal query responses with CR and
            % LF. Responses from the instrument are passed through as is. (See Prologix
            % Controller Manual)
            sp.Terminator = 'CR/LF';

            % Reduce the timeout from the default 10 seconds to speed things up
            sp.Timeout = 0.5;

            fopen(sp);

            % Configure as Controller (++mode 1), instrument address #,
            % and with read-after-write (++auto 1) enabled
            fprintf(sp, '++mode 1');
            obj.setGPIBAddress(addr);
            fprintf(sp, '++auto 1');
            fprintf(sp, '++eoi 0');
% TODO: "++eoi 1" was commented out in Austin's code... but VNA code had
% "++eoi 0"...

% TODO: how to detect that something went wrong?

            obj = obj@MotionController.MI4190(sp, axes, logger); % call superclass constructor
        end

        function setGPIBAddress(obj, addr)
            obj.addr = addr;
            fprintf(sp, '++addr %d', addr);
            obj.logger.Info(sprintf("Changed target GPIB address to %d", addr));
        end

        function addr = getGPIBAddress(obj)
            addr = obj.addr;
        end
    end
end