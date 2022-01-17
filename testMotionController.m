clc; clear all; close all;

gpib_addr = 4;
comport = "COM3";
log = Logger();
log.echoToCli(true);

% Set up the GPIB bus
buslog = Logger();
buslog.echoToCli(true);
b = GPIBBus.PrologixUsb(comport, buslog);

m = MotionController.MI4190_Prologix(b, gpib_addr, [1 2 4], log);

if (~m.isConnected())
    error("Not connected. Cannot continue.");
end