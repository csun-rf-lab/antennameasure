function [measurement] = extractMeasurement1D(results, freq)
    % EXTRACTMEASUREMENT1D extracts simple 1D measurement results for
    % analysis.

    f = find([results.data.freq] == freq);
    if isempty(f)
        error("No match in results for specified frequency (%d)", freq);
    end

    steps = results.data(f).steps;
    if length(steps(1).pos) > 1
        error("Expected only one dimension in results");
    end

    % Frequency selected by the user
    measurement.freq = freq;

    % Intermediate stuff
    actualAxesCt = length(results.data(1).steps(1).actualPos);
    stepCt = length(steps);
    actualPositions = [steps.actualPos];

    % Specific data points
    measurement.axisNames = results.meta.axisNames;
    measurement.position = [steps.pos];
    measurement.actualPosition = reshape(actualPositions, [actualAxesCt, stepCt])';
    measurement.S21 = [steps.S21];
end