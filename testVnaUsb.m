
clc; clear all; close all;


log = Logger();
log.echoToCli(true); % For debugging
%visa_address = "PXI10::CHASSIS1::SLOT1::FUNC0::INSTR";
visa_address = "TCPIP0::localhost::hislip_PXI10_CHASSIS1_SLOT1_INDEX0::INSTR";
visabus = GPIBBus.VISA(visa_address, log);


vna = VNA.Keysight_P937xA(visabus, log);

if (~vna.isConnected())
    error("Not connected. Cannot continue.");
end

%% Initialize and set config
vna.init();

vna.setStartFreq(1.0e9);
vna.setStopFreq(2.0e9);
vna.setNumPts(201);
% vna.setCenterFreq(2.5e9);
% vna.setSpan(1e9);

start = vna.getStartFreq()
stop = vna.getStopFreq()
numPts = vna.getNumPts()
center = vna.getCenterFreq()
span = vna.getSpan()


%% Now make a measurement
vna.beforeMeasurements();
results = vna.measure();
results = vna.measure();
results = vna.measure();
results = vna.measure();
results = vna.measure();
vna.afterMeasurements();

SCAL = results.SCAL;
REFP = results.REFP;
REFV = results.REFV;
freq = results.freq;
S = results.S21;


%% Plot the results

% subplot(2,2,1)
% plot(freq/1e9,20*log10(abs(S(:,1))),'-b','linewidth',2);
% hold on
% plot([freq(1) freq(end)]/1e9,[0 0],'-r','linewidth',2);
% xlabel('Frequency (GHz)');
% ylabel('|S_{11}| (dB)');
% ylim([-SCAL*REFP+REFV SCAL*(10-REFP)+REFV])
% yticks((-round(SCAL)*REFP+REFV):round(SCAL):(round(SCAL)*(10-REFP)+REFV))
% set(gca,'FontSize', 14);
% grid on
% box on
% 
% subplot(2,2,2)
% plot(freq/1e9,20*log10(abs(S(:,2))),'-b','linewidth',2);
% hold on
% plot([freq(1) freq(end)]/1e9,[0 0],'-r','linewidth',2);
% xlabel('Frequency (GHz)');
% ylabel('|S_{12}| (dB)');
% ylim([-SCAL*REFP+REFV SCAL*(10-REFP)+REFV])
% yticks((-round(SCAL)*REFP+REFV):round(SCAL):(round(SCAL)*(10-REFP)+REFV))
% set(gca,'FontSize', 14);
% grid on
% box on

%subplot(2,2,3)
%plot(freq/1e9,20*log10(abs(S(:,3))),'-b','linewidth',2);
plot(freq/1e9,20*log10(abs(S(:,1))),'-b','linewidth',2);
hold on
plot([freq(1) freq(end)]/1e9,[0 0],'-r','linewidth',2);
xlabel('Frequency (GHz)');
ylabel('|S_{21}| (dB)');
ylim([-SCAL*REFP+REFV SCAL*(10-REFP)+REFV])
yticks((-round(SCAL)*REFP+REFV):round(SCAL):(round(SCAL)*(10-REFP)+REFV))
set(gca,'FontSize', 14);
grid on
box on

% subplot(2,2,4)
% plot(freq/1e9,20*log10(abs(S(:,4))),'-b','linewidth',2);
% hold on
% plot([freq(1) freq(end)]/1e9,[0 0],'-r','linewidth',2);
% xlabel('Frequency (GHz)');
% ylabel('|S_{22}| (dB)');
% ylim([-SCAL*REFP+REFV SCAL*(10-REFP)+REFV])
% yticks((-round(SCAL)*REFP+REFV):round(SCAL):(round(SCAL)*(10-REFP)+REFV))
% set(gca,'FontSize', 14);
% grid on
% box on
% set(gcf, 'Position', [300, 150, 900, 700]);
