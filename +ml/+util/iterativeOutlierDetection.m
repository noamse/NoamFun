function OutLiersFlagOriginal = iterativeOutlierDetection(Rstd2D, M, maxIterations,Args)
    % Define input arguments with default values
    arguments
        Rstd2D (:,1) double  % Column vector of values
        M (:,1) double       % Column vector of corresponding sample points
        maxIterations (1,1) double = 3  % Default number of iterations
        Args.MoveMedianStep = 0.5;
    end

    % Sort M and Rstd2D together for proper SamplePoints usage
    [M_sorted, sortIdx] = sort(M);
    Rstd2_sorted = Rstd2D(sortIdx);

    % Initialize outlier flag vector
    OutLiersFlag = false(size(Rstd2_sorted));

    % Iterative Outlier Detection
    for iteration = 1:maxIterations
        % Identify valid (non-outlier) points from previous iterations
        validIdx = ~OutLiersFlag;

        % Run isoutlier only on valid (non-flagged) data
        OutLiersMagRMSd = false(size(Rstd2_sorted)); % Initialize
        OutLiersMagRMSd(validIdx) = isoutlier(Rstd2_sorted(validIdx), 'movmedian', Args.MoveMedianStep, 'SamplePoints', M_sorted(validIdx),ThresholdFactor=2);

        % Update the flag
        OutLiersFlag = OutLiersFlag | OutLiersMagRMSd;

        % Stop if no new outliers are found
        if ~any(OutLiersMagRMSd)
            break;
        end
    end

    % Restore original order
    OutLiersFlagOriginal = false(size(Rstd2D));
    OutLiersFlagOriginal(sortIdx) = OutLiersFlag; % Map sorted flags to original order
end