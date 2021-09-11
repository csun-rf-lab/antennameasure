function [measurement] = extractMeasurement1DFreq(results, pos)
    % EXTRACTMEASUREMENT1D extracts all frequency data from the provided
    % one-dimensional results at a specified position.

    if ~ any([results.data(1).steps.pos] == pos)
        error("No match in results for specified position (%d)", pos);
    end

    if length(results.data(1).steps(1).pos) > 1
        error("Expected only one dimension in results");
    end

    % Position selected by the user
    measurement.position = pos;

    % Specific data points
    measurement.freqs = [results.data.freq];

    % For each frequency...
    for f = 1:length(results.data)
        steps = results.data(f).steps;
        p = find([steps.pos] == pos);
        if isempty(p) % Just in case...
            error("No patch in results for specified position (%d)", pos);
        end

        measurement.S21(f) = steps(p).S21;
        measurement.actualPosition(f, :) = steps(p).actualPos;
    end

    measurement.axisNames = results.meta.axisNames;
end