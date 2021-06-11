classdef MI4190_Prologix < MotionController.MI4190
    %MI4190_PROLOGIX Class for controlling MI-4190 motion controller with
    %Prologix GPIB adapter.
    %   This class wraps the MI4190 driver and initalizes the Prologix
    %   device.

    methods
        function obj = MI4190_Prologix(comport, addr, axes)
            assert(isstring(comport), "comport must be a string.");
            assert(isinteger(addr), "addr must be an integer (GPIB address).");

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
            fprintf(sp, '++addr %d', addr);
            fprintf(sp, '++auto 1');
            fprintf(sp, '++eoi 0');
% TODO: "++eoi 1" was commented out in Austin's code... but VNA code had
% "++eoi 0"...

            % Verify connection
            fprintf(MI4190, '*idn?');
            idn = char(fread(MI4190, 100))';
            fprintf('Position Controller ID: %s\n', idn);

% TODO: how to detect that something went wrong?

            obj = obj@MotionController.MI4190(sp, axes); % call superclass constructor
        end
    end
end