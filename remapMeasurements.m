function output = remapMeasurements(input)
%REMAPMEASUREMENTS Convert measurement results to a more useful format.


    % TODO: One messy thing here is that not all of the axis positions are
    % necessarily included in the results. We could record any missing
    % values from the motion controller directly (so we'd capture whatever
    % the operator set up manually), but we'd probably want to capture that
    % only once and repeat it, since the value could change slightly while
    % the process continues (and that would result in really messy data).


    % Get the frequencies list out of the first measurement
    freqs = input(1).measurements.freq;

    for f = 1:length(freqs)
        freq = freqs(f);

        o.freq = freq;
        for r = 1:length(input)
            pos = input(r).position;
            o_step.pos = pos;
            o_step.S21 = input(r).measurements.S21(f);
            o.steps(r) = o_step;
        end

        output(f) = o;
    end
end
