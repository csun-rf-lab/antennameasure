function [b, m, vna, buslog, motlog, vnalog] = bootstrap()
%BOOTSTRAP Set up the motion controller and vna objects.
% This is designed to be a place where the physical infrastructure can be
% configured. The application can potentially pass some configuration data
% (such as comport), but there needs to be somewhere that the appropriate
% drivers are set up. This is that place.

    % Add UI components to path so application can use them
    addpath("./ui-components");

% TODO: Accept config from the application (comport, etc.)

    MI4190_gpib_addr = 4;
    HP8720_gpib_addr = 16;
    axes = [1 2 3]; % TODO: NEED TO HANDLE THIS: [1 2 4]
    comport = "/dev/ttyUSB0";

    buslog = Logger();

    % Set up the GPIB bus
    b = GPIBBus.PrologixUsb(comport, buslog);

    % Set up motion controller
    motlog = Logger();
    %m = MotionController.MI4190_Prologix(b, MI4190_gpib_addr, axes, motlog);
    m = MotionController.Dummy(axes, motlog);

    % Set up VNA
    vnalog = Logger();
    %vna = VNA.HP8720_Prologix(b, HP8720_gpib_addr, vnalog);
    vna = VNA.Dummy(vnalog);
end