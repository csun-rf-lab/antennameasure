function [b, m, vna, buslog, motlog, vnalog] = bootstrap()
%BOOTSTRAP Set up the motion controller and vna objects.
% This is designed to be a place where the physical infrastructure can be
% configured. The application can potentially pass some configuration data
% (such as comport), but there needs to be somewhere that the appropriate
% drivers are set up. This is that place.
    
% TODO: Accept config from the application (comport, etc.)

    MI4190_gpib_addr = 4;
    HP8720_gpib_addr = 16; % HP 8720B
    visa_address = "TCPIP0::localhost::hislip_PXI10_CHASSIS1_SLOT1_INDEX0::INSTR"; % Keysight P9374A
    axes = [1 2 4];
    comport = "COM3";

    vna_selection = "HP8720B"; % Uncomment to use HP 8720B VNA
    %vna_selection = "P9374A";  % Uncomment to use P9374A USB VNA
    %vna_selection = "dummy";   % Uncomment to use dummy VNA

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % Add UI components to path so application can use them
    addpath("./ui-components");

    warning('off', 'MATLAB:serial:fread:unsuccessfulRead');

    % Suppress visadev warnings about incomplete reads
    warning('off', 'transportlib:client:ReadWarning');

    buslog = Logger();

    % Set up the GPIB bus
    b = GPIBBus.PrologixUsb(comport, buslog);

    % Set up motion controller
    motlog = Logger();
    m = MotionController.MI4190_Prologix(b, MI4190_gpib_addr, axes, motlog);
    %m = MotionController.Dummy(motlog);

    % Set up VNA
    vnalog = Logger();
    vnalog.echoToCli(true); % For debugging

    switch vna_selection
    case "HP8720B"
        vna = VNA.HP8720_Prologix(b, HP8720_gpib_addr, vnalog);
    case "P9374A"
        visabus = GPIBBus.VISA(visa_address, vnalog);
        vna = VNA.Keysight_P937xA(visabus, vnalog);
    case "dummy"
        vna = VNA.Dummy(vnalog);
    end
end