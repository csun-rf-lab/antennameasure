%
% Run this script to run all unit tests.
%

clc

planUnidirectionalRunTests = matlab.unittest.TestSuite.fromClass(?planUnidirectionalRunTest);
planBidirectionalRunTests = matlab.unittest.TestSuite.fromClass(?planBidirectionalRunTest);
remapMeasurementsTest = matlab.unittest.TestSuite.fromClass(?remapMeasurementsTest);
result = run([planUnidirectionalRunTests, planBidirectionalRunTests, remapMeasurementsTest]);

table(result)