function [results] = runJob(plan, m, vna, log)
%RUNJOB Run a predetermined measurement job plan and return the results.
%   plan is the output of planJobRun()
%   m is a MotionController
%   vna is a VNA
%   log is a Logger


%%% TODO: A way to stop this thing while it runs.

    % Example: [1 2]
    axes = plan.axes;

    % plan.steps example:
    % [0 45; 0 60; 0 75; 0 90; 10 45; 10 60; 10 75; 10 90; 20 45; 20 60; 20 75; 20 90];

    log.Info("Starting job run");

    % m is a MotionController
    function setPosition(posArray, m)

        if size(posArray,2) == 1
            log.Info(sprintf("Moving to (" + string(posArray) + ")"));
        else
            log.Info(sprintf("Moving to (" + join(string(posArray), ",") + ")"));
        end

        % The fast way: Setting all axes at once
        m.moveTo(axes, posArray);

        % The slow way: setting the axis positions one at a time
        % for x = 1:length(axes)
        %     axis = axes(x);
        %     pos = posArray(x);
        %     log.Debug(sprintf("Moving axis %d to %d", axis, pos));
        %     m.moveAxisTo(axis, pos);
        % end
    end

    % vna is the vna object, which has already been configured for the
    % appropriate measurement.
    function meas = takeMeasurement(vna)
        log.Info(sprintf("Taking measurements"));
        meas = vna.measure();
    end

    % Prepare the VNA to take all of our measurements
    vna.beforeMeasurements();

    % to make matlab happy, we need to declare the empty results array as
    % an empty struct having the same fields as the structs we'll append.
    results = struct('position', {}, 'measurements', {});
    % I don't know how to get the individual sets of positions out of the
    % loop directly, so using `entry` instead.
    for entry = 1:height(plan.steps) % height is new in matlab R2020b
        posArray = plan.steps(entry,:);
        setPosition(posArray, m);
        r.position = posArray;
        r.measurements = takeMeasurement(vna);
        results(end+1) = r;
    end

    % Clean up things with the VNA now that we're done
    vna.afterMeasurements();

    % Remap the data into a useful format
    results = remapMeasurements(results);

    log.Info("Finished job run");
end