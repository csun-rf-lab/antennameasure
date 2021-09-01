function [measurement] = extractMeasurementSlice(results, freq, axisIdx, pos)
    % EXTRACTMEASUREMENTSLICE extracts a slice of the provided measurements.

    f = find([results.freq] == freq);
    if isempty(f)
        error("No match in results for specified frequency (%d)", freq);
    end

    steps = results(f).steps;
    if length(steps(1).pos) ~= 2
        error("Expected exactly two dimensions in results");
    end

    function b = otherAxis(a)
        if a == 1
            b = 2;
        else
            b = 1;
        end
    end

    % Frequency selected by the user
    measurement.freq = freq;

    % Fixed position/axis in the slice
    measurement.fixedPosition = pos;

    ct = 0;
    for s = 1:length(steps)
        step = steps(s);
        if step.pos(axisIdx) == pos
            ct = ct + 1;
            % "x" and "y" values for the measurement
            measurement.position(ct) = step.pos(otherAxis(axisIdx));
            measurement.actualPosition(ct) = step.actualPos(otherAxis(axisIdx));
            measurement.S21(ct) = step.S21;
        end
    end
end