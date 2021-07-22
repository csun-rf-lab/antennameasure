function [plan] = planJobRun(job)
%PLANJOBRUN Converts a job description to an actionable set of measurements
%to take.

    % Measurement details
    plan.freqCenter = job.freqCenter;
    plan.span = job.span;
    plan.numPts = job.numPts;

    % Now determine at what points (and in what order) we want to take the
    % measurements.

    switch (job.sweepMode)
        case "bidirectional"
            plan.steps = planBidirectionalRun(job);
        case "unidirectional"
            plan.steps = planUnidirectionalRun(job);
        otherwise
            warning("Unexpected sweep mode. No measurement points calculated.");
    end
end