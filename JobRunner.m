classdef JobRunner < handle
    %JOBRUNNER runs Plans and returns the results.
    % The class is instantiate with references to the motion controller
    % and vna (as well as a logger), and the actual job is run by calling
    % runJob() and passing the plan as the only parameter.
    
    properties
        allAxisNames % Vector of the axis names
        log          % Logger
        m            % MotionController
        vna          % VNA

        % Job run details
        startFreq
        stopFreq

        % Regular variables
        shouldStop = false % Set by stop() to bail out of a job run
        success = false
        results
    end

    events
        StateChange
    end
    
    methods
        function obj = JobRunner(allAxisNames, m, vna, log)
           obj.allAxisNames = allAxisNames;
           obj.m = m;
           obj.vna = vna;
           obj.log = log;
        end

        function results = runJob(obj, plan)
            obj.shouldStop = false;
            obj.success = false;
            obj.onStateChange(true, 0, false);

            % Example: [1 2]
            axes = plan.axes;

            % plan.steps example:
            % [0 45; 0 60; 0 75; 0 90; 10 45; 10 60; 10 75; 10 90; 20 45; 20 60; 20 75; 20 90];

            % Prepare the VNA (set params and record them)
            obj.prepVNA(plan);

            % to make matlab happy, we need to declare the empty results array as
            % an empty struct having the same fields as the structs we'll append.
            results = struct('position', {}, 'actualPosition', {}, 'measurements', {});

            % Track the last position we set so we can avoid re-setting axes that
            % haven't changed. This saves time.
            lastPos = 9999999999 * ones(1, length(axes));

            % I don't know how to get the individual sets of positions out of the
            % loop directly, so using `entry` instead.
            for entry = 1:height(plan.steps) % height is new in matlab R2020b
                if (obj.shouldStop)
                    break;
                end

                posArray = plan.steps(entry,:);
                actualPosition = obj.setPosition(axes, posArray, lastPos);

                r.position = posArray;
                r.actualPosition = actualPosition;
                r.measurements = obj.takeMeasurement();
                results(end+1) = r;
                lastPos = posArray;

                percentComplete = entry/height(plan.steps) * 100;
                obj.onStateChange(true, percentComplete, false);
            end

            % Clean up things with the VNA now that we're done
            obj.vna.afterMeasurements();

            % Remap the data into a useful format
            obj.results.meta.version = 1;
            obj.results.meta.axisNames = obj.allAxisNames(axes);
            obj.results.meta.startFreq = obj.startFreq;
            obj.results.meta.stopFreq = obj.stopFreq;
%            obj.results.meta.SCAL = results.SCAL;
%            obj.results.meta.REFP = results.REFP;
%            obj.results.meta.REFV = results.REFV;
            obj.results.data = remapMeasurements(results);

            if (obj.shouldStop)
                obj.onStateChange(false, percentComplete, false);
                obj.log.Info("Stopped job at user request");
            else
                obj.onStateChange(false, 100, false);
                obj.success = true;
                obj.log.Info("Finished job run");
            end
        end

        function success = finishedSuccessfully(obj)
            success = obj.success;
        end

        function saveResults(obj, filename)
            if (obj.success)
                results = obj.results;
                save(filename, "results");
            else
                error("No results to save because operation did not complete successfully.");
            end
        end

        function stop(obj)
            obj.shouldStop = true;
        end
    end % end methods

    methods (Access = protected)
        function actualPosition = setPosition(obj, axes, posArray, lastPos)
            if size(posArray,2) == 1
                obj.log.Info(sprintf("Moving to (" + string(posArray) + ")"));
            else
                obj.log.Info(sprintf("Moving to (" + join(string(posArray), ",") + ")"));
            end

            % The fast way: Setting all axes at once
            % Apparently the MI4190 doesn't support this...
            % TODO: Rewrite moveTo() so the looping happens internally in the
            % MI4190 driver.
            %obj.m.moveTo(axes, posArray);

            % The slow way: setting the axis positions one at a time
            for x = 1:length(axes)
                axis = axes(x);
                pos = posArray(x);

                if pos == lastPos(x)
                    obj.log.Debug(sprintf("Leaving axis %d at %d", axis, pos));
                else
                    obj.log.Debug(sprintf("Moving axis %d to %d", axis, pos));
                    obj.m.moveAxisTo(axis, pos);
                end
            end

            actualPosition = obj.m.getPositionMultiple(axes);
        end % setPosition()

        function meas = takeMeasurement(obj)
            obj.log.Info(sprintf("Taking measurements"));
            meas = obj.vna.measure();
        end

        function prepVNA(obj, plan)
            % Set measurement params
            obj.vna.setStartFreq(plan.startFreq);
            obj.vna.setStopFreq(plan.stopFreq);
            obj.vna.setNumPts(plan.numPts);

            obj.startFreq = obj.vna.getStartFreq();
            obj.stopFreq = obj.vna.getStopFreq();

            % Record the params and prep the VNA for measurements
            obj.vna.beforeMeasurements();
        end

        function onStateChange(obj, running, percentComplete, fault)
            notify(obj, "StateChange", Event.JobRunnerStateChangeEvent(running, percentComplete, fault));
        end
    end % protected methods
end

