%
% Run this script to run all unit tests.
%

clc

planUnidirectionalRunTests = matlab.unittest.TestSuite.fromClass(?planUnidirectionalRunTest);
result = run(planUnidirectionalRunTests);

table(result)