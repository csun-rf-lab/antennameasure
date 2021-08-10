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
    function actualPosition = setPosition(posArray, m, lastPos)

        if size(posArray,2) == 1
            log.Info(sprintf("Moving to (" + string(posArray) + ")"));
        else
            log.Info(sprintf("Moving to (" + join(string(posArray), ",") + ")"));
        end

        % The fast way: Setting all axes at once
        % Apparently the MI4190 doesn't support this...
        % TODO: Rewrite moveTo() so the looping happens internally in the
        % MI4190 driver.
        %m.moveTo(axes, posArray);

        % The slow way: setting the axis positions one at a time
        for x = 1:length(axes)
            axis = axes(x);
            pos = posArray(x);

            if pos == lastPos(x)
                log.Debug(sprintf("Leaving axis %d at %d", axis, pos));
            else
                log.Debug(sprintf("Moving axis %d to %d", axis, pos));
                m.moveAxisTo(axis, pos);
            end
        end

        actualPosition = m.getPositionMultiple(axes);
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
    results = struct('position', {}, 'actualPosition', {}, 'measurements', {});

    % Track the last position we set so we can avoid re-setting axes that
    % haven't changed. This saves time.
    lastPos = 9999999999 * ones(1, length(axes));
    % I don't know how to get the individual sets of positions out of the
    % loop directly, so using `entry` instead.
    for entry = 1:height(plan.steps) % height is new in matlab R2020b
        posArray = plan.steps(entry,:);
        actualPosition = setPosition(posArray, m, lastPos);

        r.position = posArray;
        r.actualPosition = actualPosition;
        r.measurements = takeMeasurement(vna);
        results(end+1) = r;
        lastPos = posArray;
    end

    % Clean up things with the VNA now that we're done
    vna.afterMeasurements();

    % Remap the data into a useful format
    results = remapMeasurements(results);

    log.Info("Finished job run");
end