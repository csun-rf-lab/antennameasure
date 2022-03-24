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
        plan
        % Actual values from VNA:
        startFreq
        stopFreq
        numPts

        % Regular variables
        shouldStop = false % Set by stop() to bail out of a job run
        success = false
        actualPosAxes
        axes
        measurements  % temporary data as the job runs
        results       % actual data to save

        % Live view
        liveView_Freq
        liveView_Axis
        liveView_SlicePosition
    end

    events
        StateChange
        MeasurementsChange
    end
    
    methods
        function obj = JobRunner(allAxisNames, m, vna, log)
           obj.allAxisNames = allAxisNames;
           obj.m = m;
           obj.vna = vna;
           obj.log = log;
        end

        function prepJob(obj, plan)
            obj.plan = plan;

            % Example: [1 2]
            obj.axes = plan.axes;
            % Specify all axes for getting the actual position
            obj.actualPosAxes = [1 2 3]; % This shouldn't really be hardcoded...

            % plan.steps example:
            % [0 45; 0 60; 0 75; 0 90; 10 45; 10 60; 10 75; 10 90; 20 45; 20 60; 20 75; 20 90];

            % Prepare the motion controller (set slew rate, etc.)
            obj.prepMotionController(plan);

            % Prepare the VNA (set params and record them)
            obj.prepVNA(plan);

            % Prepare metadata for live view
            obj.prepLiveView();
        end

        function results = runJob(obj)
            obj.shouldStop = false;
            obj.success = false;
            obj.onStateChange(true, 0, false);
            drawnow;

            plan = obj.plan;

            % to make matlab happy, we need to declare the empty results array as
            % an empty struct having the same fields as the structs we'll append.
            results = struct('position', {}, 'actualPosition', {}, 'measurements', {});

            % Track the last position we set so we can avoid re-setting axes that
            % haven't changed. This saves time.
            lastPos = 9999999999 * ones(1, length(obj.axes));

            % I don't know how to get the individual sets of positions out of the
            % loop directly, so using `entry` instead.
            for entry = 1:height(plan.steps) % height is new in matlab R2020b
                if (obj.shouldStop)
                    break;
                end

                posArray = plan.steps(entry,:);
                actualPosition = obj.setPosition(obj.axes, posArray, lastPos);

                r.position = posArray;
                r.actualPosition = actualPosition;
                r.measurements = obj.takeMeasurement();
                results(end+1) = r;
                lastPos = posArray;

                percentComplete = entry/height(plan.steps) * 100;
                obj.onStateChange(true, percentComplete, false);

                obj.measurements = results;
                obj.onMeasurementsChange();
                drawnow;
            end

            % Clean up things with the VNA now that we're done
            obj.vna.afterMeasurements();

            % Remap the data into a useful format
            obj.results = obj.mapResults();

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

        function freq = getLiveViewFrequenciesAvailable(obj)
            % For simplicity, right now we assume the frequencies available
            % from the HP8720 driver. If other drivers are added, this
            % should be reworked to determine the available frequencies
            % from the selected driver.
            % Additionally, this should probably be determined after the
            % VNA is prepped, so we can verify that the start/stop and
            % numPts are acceptable to the VNA.

            startFreq = obj.startFreq;
            stopFreq = obj.stopFreq;
            numPts = obj.numPts;
            if (startFreq == stopFreq)
                freq = [startFreq];
            else
                freq = 1e5*round((startFreq:(stopFreq-startFreq)/(numPts-1):stopFreq)/1e5);
            end
        end

        function freq = getLiveViewFrequency(obj)
            freq = obj.liveView_Freq;
        end

        function setLiveViewFrequency(obj, freq)
            obj.liveView_Freq = freq;
            obj.onMeasurementsChange();
        end

        function axis = getLiveViewAxis(obj)
            axis = obj.liveView_Axis;
        end

        function setLiveViewAxis(obj, axis)
            obj.liveView_Axis = axis;

            % When changing axis, pick a default slice
            slices = obj.getLiveViewSlicesAvailable();
            obj.setLiveViewSlicePosition(slices(ceil(end/2)));
        end

        function slices = getLiveViewSlicesAvailable(obj)
            axisIdx = find(obj.axes == obj.liveView_Axis);
            slices = unique(obj.plan.steps(:, axisIdx));
        end

        function slice = getLiveViewSlicePosition(obj)
            slice = obj.liveView_SlicePosition;
        end

        function setLiveViewSlicePosition(obj, slice)
            obj.liveView_SlicePosition = slice;
        end
    end % end methods

    methods (Access = protected)
        % Refresh the job-in-progress measurements display
        function onMeasurementsChange(obj)
            r = obj.mapResults();

            % Process results differently depending on number of axes
            switch(length(obj.axes))
                case 1
                    data = extractMeasurement1D(r, obj.liveView_Freq);

                case 2
                    axisIdx = find(obj.axes == obj.liveView_Axis);
                    data = extractMeasurementSlice(r, obj.liveView_Freq, axisIdx, obj.liveView_SlicePosition);

                % TODO: 3-axis measurements
                otherwise
                    error("Unexpected axis count");
            end

            if isfield(data, "S21")
                positions = data.actualPosition;
                S21 = data.S21;
            else
                % No data yet
                positions = [0];
                S21 = [0];
            end

            notify(obj, "MeasurementsChange", Event.JobRunnerMeasurementsChangeEvent(positions, S21));

            drawnow; % Process events and update UI/figures immediately
        end

        function prepLiveView(obj)
            % Default to the middle frequency in our range
            freqs = obj.getLiveViewFrequenciesAvailable();
            obj.liveView_Freq = freqs(ceil(end/2));

            % For now, just default to the "first" axis
            obj.liveView_Axis = obj.axes(1);

            % Default to the middle position of the axis in question
            slices = obj.getLiveViewSlicesAvailable();
            obj.liveView_SlicePosition = slices(ceil(end/2));
        end

        function actualPosition = setPosition(obj, axes, posArray, lastPos)
            if size(posArray,2) == 1
                obj.log.Info(sprintf("Moving to (" + string(posArray) + ")"));
            else
                obj.log.Info(sprintf("Moving to (" + join(string(posArray), ",") + ")"));
            end

            % The fast way: Setting all axes at once
            % Apparently the MI4190 doesn't support this...
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

            actualPosition = obj.m.getPositionMultiple(obj.actualPosAxes);
        end % setPosition()

        function meas = takeMeasurement(obj)
            obj.log.Info(sprintf("Taking measurements"));
            meas = obj.vna.measure();
        end

        function prepMotionController(obj, plan)
            actual1 = obj.m.setSlewVelocity(1, 4);
            actual2 = obj.m.setSlewVelocity(2, 4);
            actual3 = obj.m.setSlewVelocity(3, 4);
            % fprintf("\n\nActual slew velocities: %f %f %f\n\n", actual1, actual2, actual3);
        end

        function prepVNA(obj, plan)
            % Initialize VNA
            obj.vna.init();
            
            % Set measurement params
            if plan.startFreq == plan.stopFreq
                obj.vna.setSingleFreq(plan.startFreq);
                cwfreq = obj.vna.getSingleFreq();
                obj.startFreq = cwfreq;
                obj.stopFreq = cwfreq;
                obj.numPts = 1;
            else
                obj.vna.setStartFreq(plan.startFreq);
                obj.vna.setStopFreq(plan.stopFreq);
                obj.vna.setNumPts(plan.numPts);
                % Make sure we represent things correctly in the result
                obj.startFreq = obj.vna.getStartFreq();
                obj.stopFreq = obj.vna.getStopFreq();
                obj.numPts = obj.vna.getNumPts();
            end

            % Record the params and prep the VNA for measurements
            obj.vna.beforeMeasurements();
        end

        function results = mapResults(obj)
            results.meta.version = 1;
            results.meta.axisNames = obj.allAxisNames(obj.axes);
            results.meta.actualPositionAxisNames = obj.allAxisNames(obj.actualPosAxes);
            results.meta.startFreq = obj.startFreq;
            results.meta.stopFreq = obj.stopFreq;
%            results.meta.SCAL = results.SCAL;
%            results.meta.REFP = results.REFP;
%            results.meta.REFV = results.REFV;
            results.data = remapMeasurements(obj.measurements);
        end

        function onStateChange(obj, running, percentComplete, fault)
            notify(obj, "StateChange", Event.JobRunnerStateChangeEvent(running, percentComplete, fault));
        end
    end % protected methods
end

