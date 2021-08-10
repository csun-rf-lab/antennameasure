%
% See runTests.m
%
% Based in part on https://www.mathworks.com/help/matlab/matlab_prog/analyze-testsolver-results.html

classdef remapMeasurementsTest < matlab.unittest.TestCase
    methods(Test)
        function mapTwoAxes_SingleFreq(testCase)
            input(1).position = [0 0];
            input(1).measurements.freq = [1000];
            input(1).measurements.S21 = [1 + j];
            input(2).position = [0 10];
            input(2).measurements.freq = input(1).measurements.freq;
            input(2).measurements.S21 = [0];
            input(3).position = [0 20];
            input(3).measurements.freq = input(1).measurements.freq;
            input(3).measurements.S21 = [0 + j];

            expected(1).freq = 1000;
            expected(1).steps(1).pos = [0 0];
            expected(1).steps(1).S21 = 1 + j;
            expected(1).steps(2).pos = [0 10];
            expected(1).steps(2).S21 = 0;
            expected(1).steps(3).pos = [0 20];
            expected(1).steps(3).S21 = j;

            actual = remapMeasurements(input);

            testCase.verifyEqual(actual, expected);
        end

        function mapTwoAxes_MultipleFreqs(testCase)
            input(1).position = [0 0];
            input(1).measurements.freq = [1000 2000 3000];
            input(1).measurements.S21 = [1 + j; 2 + 2*j; 3 + 3*j];
            input(2).position = [0 10];
            input(2).measurements.freq = input(1).measurements.freq;
            input(2).measurements.S21 = [0; 1; 2];
            input(3).position = [0 20];
            input(3).measurements.freq = input(1).measurements.freq;
            input(3).measurements.S21 = [0 + j; 1 + j; 2 + j];

            expected(1).freq = 1000;
            expected(1).steps(1).pos = [0 0];
            expected(1).steps(1).S21 = 1 + j;
            expected(1).steps(2).pos = [0 10];
            expected(1).steps(2).S21 = 0;
            expected(1).steps(3).pos = [0 20];
            expected(1).steps(3).S21 = j;

            expected(2).freq = 2000;
            expected(2).steps(1).pos = [0 0];
            expected(2).steps(1).S21 = 2 + 2*j;
            expected(2).steps(2).pos = [0 10];
            expected(2).steps(2).S21 = 1;
            expected(2).steps(3).pos = [0 20];
            expected(2).steps(3).S21 = 1 + j;

            expected(3).freq = 3000;
            expected(3).steps(1).pos = [0 0];
            expected(3).steps(1).S21 = 3 + 3*j;
            expected(3).steps(2).pos = [0 10];
            expected(3).steps(2).S21 = 2;
            expected(3).steps(3).pos = [0 20];
            expected(3).steps(3).S21 = 2 + j;

            actual = remapMeasurements(input);

            testCase.verifyEqual(actual, expected);
        end
    end
end