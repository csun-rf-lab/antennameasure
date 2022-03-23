% Script to compare patterns
close all; clear all; clc;

file1 = 'C:\Users\CSUN\Documents\Antenna Measurements\DHRA results 20220118-1.mat';
file2 = 'C:\Users\CSUN\Documents\Antenna Measurements\DHRA results 20220118-4.mat';
freq = [2 3 4 5 6 8]*1e9;

for f = 1:length(freq)
    load(file1);
    data1 = extractMeasurement1D(results, freq(f));
    gain1 = 20*log10(abs(data1.S21));
    ind0 = find(data1.position == 0);
    gain1_0 = gain1(ind0);
    maxGain1 = max(gain1);
    figure
    plot(data1.position,gain1-maxGain1,'-b','LineWidth',2);
    hold on
    ylim([-10 10])
    
    load(file2);
    data2 = extractMeasurement1D(results, freq(f));
    gain2 = 20*log10(abs(data2.S21));
    ind0 = find(data2.position == 0);
    gain2_0 = gain2(ind0);
    plot(data2.position,gain2-maxGain1,'-r','LineWidth',2);
    xlabel('\theta (deg.)')
    ylabel('Normalized Gain (dBi)')
    grid on
    box on
    ylim([-10 10])
    title(['Frequency: ' num2str(freq(f)/1e9) ' GHz'])
    legend('Horn 1','Horn 2')
    
    gainDiff(f) = gain1_0-gain2_0;

end

figure
plot(freq/1e9,gainDiff,'b','LineWidth',2)
grid on
xlabel('Frequency (GHz)')
ylabel('Gain Difference (dB)')


