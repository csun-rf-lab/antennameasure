
clc; clear all; close all;

gpib_addr = 16;
comport = "COM6";
log = Logger();


vna = VNA.HP8720_Prologix(comport, gpib_addr, log);

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
results = vna.measure();

SCAL = results.SCAL;
REFP = results.REFP;
REFV = results.REFV;
freq = results.freq;
S = results.S;


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
