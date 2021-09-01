function [measurement] = extractMeasurement1D(results, freq)
    % EXTRACTMEASUREMENT1D extracts simple 1D measurement results for
    % analysis.

    f = find([results.freq] == freq);
    if isempty(f)
        error("No match in results for specified frequency (%d)", freq);
    end

    steps = results(f).steps;
    if length(steps(1).pos) > 1
        error("Expected only one dimension in results");
    end

    % Frequency selected by the user
    measurement.freq = freq;

    % Specific data points
    measurement.position = [steps.pos];
    measurement.actualPosition = [steps.actualPos];
    measurement.S21 = [steps.S21];
end