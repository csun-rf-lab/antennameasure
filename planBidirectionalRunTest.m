%
% See runTests.m
%
% Based in part on https://www.mathworks.com/help/matlab/matlab_prog/analyze-testsolver-results.html

classdef planBidirectionalRunTest < matlab.unittest.TestCase
    methods(Test)
        function oneAxis(testCase)
            job.version = 1;
            job.sweepMode = "unidirectional";
            job.axes(1).enable = "On";
            job.axes(1).start = 0;
            job.axes(1).stop = 90;
            job.axes(1).increment = 10;
            job.axes(2).enable = "Off";
            job.axes(3).enable = "Off";
            expectedAxes = [1];
            expectedPositions = (0 : 10 : 90)';
            [actualAxes, actualPositions] = planBidirectionalRun(job);
            testCase.verifyEqual(actualAxes, expectedAxes)
            testCase.verifyEqual(actualPositions, expectedPositions)
        end

        function twoAxes(testCase)
            job.version = 1;
            job.sweepMode = "unidirectional";
            job.axes(1).enable = "On";
            job.axes(1).start = 0;
            job.axes(1).stop = 20;
            job.axes(1).increment = 10;
            job.axes(2).enable = "On";
            job.axes(2).start = 45;
            job.axes(2).stop = 90;
            job.axes(2).increment = 15;
            job.axes(3).enable = "Off";
            expectedAxes = [2 1];
            expectedPositions = [45 0; 45 10; 45 20; 60 20; 60 10; 60 0; 75 0; 75 10; 75 20; 90 20; 90 10; 90 0];
            [actualAxes, actualPositions] = planBidirectionalRun(job);
            testCase.verifyEqual(actualAxes, expectedAxes)
            testCase.verifyEqual(actualPositions, expectedPositions)
        end

        function twoAxes_OneFixed(testCase)
            job.version = 1;
            job.sweepMode = "unidirectional";
            job.axes(1).enable = "On";
            job.axes(1).start = 90;
            job.axes(1).stop = 90;
            job.axes(1).increment = 10;
            job.axes(2).enable = "On";
            job.axes(2).start = 45;
            job.axes(2).stop = 90;
            job.axes(2).increment = 15;
            job.axes(3).enable = "Off";
            expectedAxes = [2 1];
            expectedPositions = [45 90; 60 90; 75 90; 90 90];
            [actualAxes, actualPositions] = planBidirectionalRun(job);
            testCase.verifyEqual(actualAxes, expectedAxes)
            testCase.verifyEqual(actualPositions, expectedPositions)
        end

        function threeAxes(testCase)
            job.version = 1;
            job.sweepMode = "unidirectional";
            job.axes(1).enable = "On";
            job.axes(1).start = 0;
            job.axes(1).stop = 10;
            job.axes(1).increment = 10;
            job.axes(2).enable = "On";
            job.axes(2).start = 60;
            job.axes(2).stop = 70;
            job.axes(2).increment = 10;
            job.axes(3).enable = "On";
            job.axes(3).start = 10;
            job.axes(3).stop = 20;
            job.axes(3).increment = 10;
            expectedAxes = [3 2 1];
            expectedPositions = [10 60 0; 10 60 10; 10 70 10; 10 70 0; 20 70 0; 20 70 10; 20 60 10; 20 60 0];
            [actualAxes, actualPositions] = planBidirectionalRun(job);
            testCase.verifyEqual(actualAxes, expectedAxes)
            testCase.verifyEqual(actualPositions, expectedPositions)
        end

        function oneAxis_NonsensicalIncrement(testCase)
            job.version = 1;
            job.sweepMode = "unidirectional";
            job.axes(1).enable = "On";
            job.axes(1).start = 0;
            job.axes(1).stop = 90;
            job.axes(1).increment = 89;
            job.axes(2).enable = "Off";
            job.axes(3).enable = "Off";
            expectedAxes = [1];
            expectedPositions = [0 90]';
            [actualAxes, actualPositions] = planBidirectionalRun(job);
            testCase.verifyEqual(actualAxes, expectedAxes)
            testCase.verifyEqual(actualPositions, expectedPositions)
        end
% Errors example:
%         function nonnumericInput(testCase)
%             testCase.verifyError(@()quadraticSolver(1,'-3',2), ...
%                 'quadraticSolver:InputMustBeNumeric')
%         end
    end
end