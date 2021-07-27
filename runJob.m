function [results] = runJob(job, m, vna, log)
%RUNJOB Run a predetermined measurement job and return the results.
%   m is a MotionController
%   vna is a VNA
%   log is a Logger


%%% TODO: A way to stop this thing while it runs.

    axes = job.axes;

% axes = [1];
% job.positions = (0 : 10 : 90)';
%
%axes = [1 2];
%job.positions = [0 45; 0 60; 0 75; 0 90; 10 45; 10 60; 10 75; 10 90; 20 45; 20 60; 20 75; 20 90];
% 
% axes = [1 2 4];
% job.positions = [0 60 10; 0 60 20; 0 70 10; 0 70 20; 10 60 10; 10 60 20; 10 70 10; 10 70 20];

    log.Info("Starting job run");

    % m is a MotionController
    function setPosition(posArray, m)
% TODO: A position function that lets you set all of the axes
% simultaneously
        if size(posArray,2) == 1
            log.Info(sprintf("Moving to (" + string(posArray) + ")"));
        else
            log.Info(sprintf("Moving to (" + join(string(posArray), ",") + ")"));
        end

        for x = 1:length(axes)
            axis = axes(x);
            pos = posArray(x);
            log.Debug(sprintf("Moving axis %d to %d", axis, pos));
            m.moveTo(axis, pos);
        end
    end

    % vna is the vna object, which has already been configured for the
    % appropriate measurement.
    function meas = takeMeasurement(vna)
        log.Info(sprintf("Taking measurements"));
        meas = vna.measure();
    end

    % to make matlab happy, we need to declare the empty results array as
    % an empty struct having the same fields as the structs we'll append.
    results = struct('position', {}, 'measurements', {});
    % I don't know how to get the individual sets of positions out of the
    % loop directly, so using `entry` instead.
    for entry = 1:height(job.positions) % height is new in matlab R2020b
        posArray = job.positions(entry,:);
        setPosition(posArray);
        r.position = posArray;
        r.measurements = takeMeasurement();
        results(end+1) = r;
    end

    log.Info("Finished job run");
end