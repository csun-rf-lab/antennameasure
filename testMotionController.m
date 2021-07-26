clc; clear all; close all;

gpib_addr = 4;
comport = "/dev/ttyUSB0";
log = Logger();


m = MotionController.MI4190_Prologix(comport, gpib_addr, [1 2 4], log);

if (~m.isConnected())
    error("Not connected. Cannot continue.");
end