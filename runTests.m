%
% Run this script to run all unit tests.
%

clc

planUnidirectionalRunTests = matlab.unittest.TestSuite.fromClass(?planUnidirectionalRunTest);
planBidirectionalRunTests = matlab.unittest.TestSuite.fromClass(?planBidirectionalRunTest);
result = run([planUnidirectionalRunTests, planBidirectionalRunTests]);

table(result)