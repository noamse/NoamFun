function OutLiersFlagOriginal = OutliersDetectionCustum(Rstd2D, M, ~, Args)
    % Rstd2D: Column vector of RMS values (Y-axis)
    % M: Column vector of Magnitude values (X-axis)
    % maxIterations: (Unused in this robust method, kept for compatibility)
    % Args: Struct with optional fields
    
    arguments
        Rstd2D (:,1) double
        M (:,1) double
        ~ 
        Args.BinWidth = 0.5;      % Width of magnitude bin
        Args.MinStarsPerBin = 10; % Minimum stars to calculate stats
        Args.SigmaThresh = 4.0;   % Rejection threshold (Sigma)
    end

    % 1. Sort Data by Magnitude
    [M_sorted, sortIdx] = sort(M);
    Rstd2_sorted = Rstd2D(sortIdx);
    
    % Initialize Flag
    OutLiersFlag = false(size(Rstd2D));
    
    % 2. Define Magnitude Bins
    % We create overlapping bins (sliding window) for smoothness, 
    % or simple distinct bins. Distinct bins are safer for detection.
    minMag = min(M);
    maxMag = max(M);
    edges = minMag : Args.BinWidth : maxMag;
    
    % 3. Loop over bins
    % We calculate the threshold purely based on the local population
    for i = 1:length(edges)-1
        binMask = (M_sorted >= edges(i)) & (M_sorted < edges(i+1));
        
        % Check if we have enough stars to trust the statistics
        if sum(binMask) < Args.MinStarsPerBin
            % CASE: Sparse Region (Bright stars)
            % If we have too few stars, we cannot calculate a robust scatter.
            % STRATEGY: Borrow the threshold from the *nearest valid neighbor bin*
            % or use a global minimum noise floor (e.g., 10 mas).
            
            % For now, let's look at the global median of the nearest 20 stars
            % This is a "Fallback" local median
            centerIdx = find(binMask, 1);
            if isempty(centerIdx), continue; end
            
            nbStart = max(1, centerIdx - 10);
            nbEnd   = min(length(M_sorted), centerIdx + 10);
            localSlice = Rstd2_sorted(nbStart:nbEnd);
            
            medVal = median(localSlice);
            madVal = median(abs(localSlice - medVal));
            sigma  = 1.4826 * madVal;
        else
            % CASE: Dense Region (Faint stars)
            % Standard Robust Statistics
            binData = Rstd2_sorted(binMask);
            medVal  = median(binData);
            madVal  = median(abs(binData - medVal));
            sigma   = 1.4826 * madVal;
        end
        
        % 4. Apply Cut
        % Limit = Median + N * Sigma
        % We ensure sigma isn't zero (if all stars are identical)
        sigma = max(sigma, 1e-6); 
        
        threshold = medVal + Args.SigmaThresh * sigma;
        
        % Identify outliers in this bin
        localOutliers = binMask & (Rstd2_sorted > threshold);
        
        % Map back to sorted array
        OutLiersFlag(sortIdx(localOutliers)) = true;
    end
    
    % Restore original order
    OutLiersFlagOriginal = OutLiersFlag;
end