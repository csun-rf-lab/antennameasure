
%% this is untested. Don't use it unless you know what you're doing.

farfield1_f = "../../Antenna Measurements/ESJ_Realized_Gain results 20220408-2006.mat";
farfield2_f = "../../Antenna Measurements/ESJ_Realized_Gain results 20220408-2022.mat";
angle = 0; % degrees

farfield1results = load(farfield1_f, "results");
farfield2results = load(farfield2_f, "results");

data1 = extractMeasurement1DFreq(farfield1results.results, angle);
data2 = extractMeasurement1DFreq(farfield2results.results, angle);

E_RHCP = (data1.S21 + j*data2.S21)/sqrt(2);
E_LHCP = (data1.S21 - j*data2.S21)/sqrt(2);

figure;
plot(data1.freqs, 20*log10(abs(E_RHCP)), "linewidth", 2);
title("RHCP");
xlabel("Frequency (Hz)");
ylabel("Magnitude (dB)");
grid on;

figure;
plot(data1.freqs, 20*log10(abs(E_LHCP)), "linewidth", 2);
title("LHCP");
xlabel("Frequency (Hz)");
ylabel("Magnitude (dB)");
grid on;