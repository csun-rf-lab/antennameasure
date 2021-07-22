%
% Run this script to run all unit tests.
%

clc

planBidirectionalRunTests = matlab.unittest.TestSuite.fromClass(?planBidirectionalRunTest);
result = run(planBidirectionalRunTests);

table(result)