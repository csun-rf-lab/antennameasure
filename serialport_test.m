if ~isempty(instrfind)
    fclose(instrfind)
    delete(instrfind)
end

sp = serialport("COM3", 9600, "Timeout", 0.5);
%                sp = serial("/dev/ttyUSB0");

                % Prologix Controller 4.2 requires CR as command terminator, LF is
                % optional. The controller terminates internal query responses with CR and
                % LF. Responses from the instrument are passed through as is. (See Prologix
                % Controller Manual)
                %sp.configureTerminator('CR/LF');
                %sp.Terminator = 'CR/LF';
                configureTerminator(sp,"LF")

                % Reduce the timeout from the default 10 seconds to speed things up
                %sp.Timeout = 0.5;

                %fclose(sp);
                %fopen(sp);

                pause(1);

                % Configure as Controller (++mode 1), instrument address #,
                % and with read-after-write (++auto 1) enabled
%                 fprintf(sp, '++mode 1');
%                 fprintf(sp, sprintf('++addr %d', 4));
%                 fprintf(sp, '++auto 1');
%                 fprintf(sp, '++eoi 1');
                writeline(sp, '++mode 1');
                writeline(sp, sprintf('++addr %d', 4));
                writeline(sp, '++auto 1');
                writeline(sp, '++eoi 1');
% TODO: "++eoi 1" was commented out in Austin's code... but VNA code had
% "++eoi 0"...
pause(1);

                % Verify connection
                %fprintf(obj.sp, '*CLS'); % clear output/error queues
                fprintf(sp, '++ver');
                pause(1);
                msgv = char(fread(sp, 100))';
                pause(1);
                fprintf(sp, '*idn?');
                pause(1);
                msgidn = char(fread(sp, 100))';