
clc; clear all; close all;

MI4190_gpib_addr = 4;
HP8720_gpib_addr = 16;
axes = [1 2 4];

comport = "/dev/ttyUSB0";
buslog = Logger();

b = GPIBBus.PrologixUsb(comport, buslog);

if (~b.isConnected())
    error("Not connected. Cannot continue.");
end

%% Now create the VNA and motion controller objects

vnalog = Logger();
vna = VNA.HP8720_Prologix(b, HP8720_gpib_addr, vnalog);

motlog = Logger();
m = MotionController.MI4190_Prologix(b, MI4190_gpib_addr, axes, motlog);


%% And see if we can talk to both of them

start = vna.getStartFreq()
stop = vna.getStopFreq()
numPts = vna.getNumPts()
center = vna.getCenterFreq()
span = vna.getSpan()

axis1pos = m.getPosition(1)
axis2pos = m.getPosition(2)
axis4pos = m.getPosition(4)

%% For the grand finale... can we run a job?

job.axes = [1];
job.positions = (0 : 10 : 90)';
%
%job.axes = [1 2];
%job.positions = [0 45; 0 60; 0 75; 0 90; 10 45; 10 60; 10 75; 10 90; 20 45; 20 60; 20 75; 20 90];
% 
%job.axes = [1 2 4];
%job.positions = [0 60 10; 0 60 20; 0 70 10; 0 70 20; 10 60 10; 10 60 20; 10 70 10; 10 70 20];

joblog = Logger();
results = runJob(job, m, vna, joblog)

