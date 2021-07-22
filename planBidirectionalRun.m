function [steps] = planBidirectionalRun(job)
    % Axes earlier in the precedence array will increment slowest,
    % while axes later will be incremented more quickly.
    % TODO: That's a horrible way to explain this. Come up with a better
    % one.
    precedence = [1 2 3];

    function [subresult] = calcSteps(remainingAxes)
        thisAxis = remainingAxes(1);
        s = linspace(thisAxis.start, thisAxis.stop, ((thisAxis.stop - thisAxis.start) / thisAxis.increment)+1);
        if (length(remainingAxes) == 1)
            subresult = s';
        else
            subresult = [];
            substeps = calcSteps(remainingAxes(2:end));
            for x = s
% TODO: Need to store this in a way that the axis ids are included.
                local = x * ones(length(substeps), 1);
                localCombined = [local substeps];
                subresult = [subresult; localCombined];
            end
        end
    end

    % First, determine which axes we're going to control,
    % in the appropriate order (with respect to "precedence")
    enabledAxes = [];
    for i = (1:length(precedence))
        axisNum = precedence(i);
        axis = job.axes(axisNum);
        if (axis.enable == "On")
            enabledAxes = [enabledAxes axis];
        end
    end

    if isempty(enabledAxes)
        error("No axes enabled.");
    else
        steps = calcSteps(enabledAxes);
    end
end