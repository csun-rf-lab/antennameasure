close all; clear all; clc;

COMport = 'COM3';

if ~isempty(instrfind)
    fclose(instrfind);
    delete(instrfind);
end

vna = serial(COMport);

vna.Terminator = 'LF';

vna.Timeout = 0.5;

vna.InputBufferSize = 100000;

fopen(vna)

warning('off','MATLAB:serial:fread:unsuccessfulRead');

fprintf(vna, '++mode 1');
fprintf(vna, '++addr 4'); % 4 is for the MI-4190
%fprintf(vna, '++addr 16'); % 16 is for the VNA
fprintf(vna, '++auto 1');
fprintf(vna, '++eoi 1');

fprintf(vna, '*idn?');
idn = char(fread(vna,30))'

fclose(vna);