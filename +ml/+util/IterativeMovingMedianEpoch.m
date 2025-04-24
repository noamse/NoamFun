function [OutLiersFlagOriginal, MovingMedian] = IterativeMovingMedianEpoch(R, M, maxIterations, windowSize)
% IterativeMovingMedianEpoch - Iteratively detect outliers and compute moving median.
%
% Inputs:
%   R            - Matrix (rows = datasets, columns = time samples)
%   M            - Column vector of time/sample points (length must match size(R,2))
%   maxIterations - Max number of iterations (default = 3)
%   windowSize    - Window size for moving median (default = 0.5)
%
% Outputs:
%   OutLiersFlagOriginal - Logical matrix of outlier flags (same size as R)
%   MovingMedian         - Matrix of moving median values (same size as R)

arguments
    R (:,:) double
    M (:,1) double
    maxIterations (1,1) double = 3
    windowSize (1,1) double = 0.5
end

[numRows, numCols] = size(R);

if length(M) ~= numCols
    error('The number of columns in R must match the length of M.');
end

% Pre-sort M once
[M_sorted, sortIdx] = sort(M);
Rsorted = R(:,sortIdx);

OutLiersFlagOriginal = false(size(R));
MovingMedian = NaN(size(R));

for rowIdx = 1:numRows
    R_row_sorted = Rsorted(rowIdx,:)';
    OutLiersFlag = false(size(R_row_sorted));

    for iteration = 1:maxIterations
        validIdx = ~OutLiersFlag;

        % Apply isoutlier with movmedian only on non-outliers
        OutLiersMagRMSd = false(size(R_row_sorted));
        OutLiersMagRMSd(validIdx) = isoutlier(R_row_sorted(validIdx) ,'movmedian', windowSize,'SamplePoints', M_sorted(validIdx),'ThresholdFactor',3);

        if ~any(OutLiersMagRMSd & ~OutLiersFlag)
            break;
        end

        OutLiersFlag = OutLiersFlag | OutLiersMagRMSd;
    end

    % Final moving median using non-outliers
    temp = R_row_sorted;
    temp(OutLiersFlag) = NaN;
    MovingMedian_row = movmedian(temp, windowSize,'omitnan', 'SamplePoints', M_sorted);
    
    OutLiersFlag(R_row_sorted(validIdx)<(MovingMedian_row(validIdx))) = false;
    % Map back to original order
    OutLiersFlagOriginal(rowIdx, sortIdx) = OutLiersFlag;
    MovingMedian(rowIdx, sortIdx) = MovingMedian_row;
end
end


%function [OutLiersFlagOriginal, MovingMedian] = IterativeMovingMedianEpoch(R, M, maxIterations, windowSize)
%     % Define input arguments with default values
%     arguments
%         R (:,:) double        % Matrix where rows are datasets and columns match M
%         M (:,1) double        % Column vector of sample points (same number of columns as R)
%         maxIterations (1,1) double = 3  % Default number of iterations
%         windowSize (1,1) double = 0.5   % Default moving window size
%     end
% 
%     % Get the number of rows and columns
%     [numRows, numCols] = size(R);
% 
%     % Ensure M has the correct dimensions
%     if length(M) ~= numCols
%         error('The number of columns in R must match the length of M.');
%     end
% 
%     % Initialize output matrices
%     OutLiersFlagOriginal = false(size(R)); % Logical matrix for outliers
%     MovingMedian = NaN(size(R)); % Matrix to store moving median values
%     [M_sorted, sortIdx] = sort(M);
%     Rsorted = R(:,sortIdx);
%     % Iterate over each row separately
%     for rowIdx = 1:numRows
%         % Extract current row of R
%         %R_row = R(rowIdx, :)';
% 
%         % Sort M and R_row together for proper SamplePoints usage
%         R_row_sorted = Rsorted(rowIdx,:)';%R_row(sortIdx);
% 
%         % Initialize outlier flag vector for this row
%         OutLiersFlag = false(size(R_row_sorted));
% 
%         % Iterative Outlier Detection
%         for iteration = 1:maxIterations
%             % Identify valid (non-outlier) points from previous iterations
%             validIdx = ~OutLiersFlag;
% 
%             % Run isoutlier only on valid (non-flagged) data with user-defined window size
%             OutLiersMagRMSd = false(size(R_row_sorted)); % Initialize
%             OutLiersMagRMSd(validIdx) = isoutlier(R_row_sorted(validIdx), 'movmedian', windowSize, 'SamplePoints', M_sorted(validIdx));
% 
%             % Update the flag
%             OutLiersFlag = OutLiersFlag | OutLiersMagRMSd;
% 
%             % Stop if no new outliers are found
%             if ~any(OutLiersMagRMSd)
%                 break;
%             end
%         end
% 
%         % Compute Moving Median after removing detected outliers using user-defined window size
%         MovingMedian_row = NaN(size(R_row_sorted)); % Initialize with NaN
%         validIdx = ~OutLiersFlag; % Use only non-outlier values
%         MovingMedian_row(validIdx) = movmedian(R_row_sorted(validIdx), windowSize, 'SamplePoints', M_sorted(validIdx));
% 
%         % Restore original order
%         OutLiersFlagOriginal(rowIdx, sortIdx) = OutLiersFlag; % Map sorted flags to original order
%         MovingMedian(rowIdx, sortIdx) = MovingMedian_row; % Map sorted moving median to original order
%     end
% end