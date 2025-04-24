function [OutLiersFlagOriginal, MovingMedian] = IterativeMovingMedian(Rstd2D, M, maxIterations, windowSize)
    % Define input arguments with default values
    arguments
        Rstd2D (:,1) double  % Column vector of values
        M (:,1) double       % Column vector of corresponding sample points
        maxIterations (1,1) double = 10  % Default number of iterations
        windowSize (1,1) double = 0.5   % Default moving window size
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

        % Run isoutlier only on valid (non-flagged) data with user-defined window size
        OutLiersMagRMSd = false(size(Rstd2_sorted)); % Initialize
        OutLiersMagRMSd(validIdx) = isoutlier(Rstd2_sorted(validIdx), 'movmedian', windowSize, 'SamplePoints', M_sorted(validIdx));

        % Update the flag
        OutLiersFlag = OutLiersFlag | OutLiersMagRMSd;

        % Stop if no new outliers are found
        if ~any(OutLiersMagRMSd)
            break;
        end
    end

    % Compute Moving Median after removing detected outliers using user-defined window size
    MovingMedian = NaN(size(Rstd2_sorted)); % Initialize with NaN
    validIdx = ~OutLiersFlag; % Use only non-outlier values
    MovingMedian(validIdx) = movmedian(Rstd2_sorted(validIdx), windowSize, 'SamplePoints', M_sorted(validIdx));

    % Restore original order
    OutLiersFlagOriginal = false(size(Rstd2D));
    MovingMedianOriginal = NaN(size(Rstd2D));

    OutLiersFlagOriginal(sortIdx) = OutLiersFlag; % Map sorted flags to original order
    MovingMedianOriginal(sortIdx) = MovingMedian; % Map sorted moving median to original order

    % Return the results
    MovingMedian = MovingMedianOriginal;
end