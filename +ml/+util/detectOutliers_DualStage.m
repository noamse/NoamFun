function [FinalOutlierFlag, DebugInfo] = detectOutliers_DualStage(RMS, Mag, Args)
% DETECTRMSOUTLIERS_ADAPTIVE
    % Uses ADAPTIVE BINNING to handle fields with low star counts.
    % Fixes interp1 error by manually handling extrapolation.
    
    arguments
        RMS (:,1) double
        Mag (:,1) double
        Args.Tightness = 2.0;    % Stricter < 2.0 < Looser
        Args.MinBinSize = 15;    % Minimum stars required per bin
        Args.MaxBins = 20;       % Don't make more bins than this
    end
    
    % --- Remove NaNs first ---
    valid_data = ~isnan(RMS) & ~isnan(Mag);
    RMS_valid = RMS(valid_data);
    Mag_valid = Mag(valid_data);
    
    N_Total = length(RMS_valid);
    
    % Initialize output (False by default)
    FinalOutlierFlag = false(size(RMS));
    
    % --- STAGE 1: Check Data Sufficiency ---
    if N_Total < Args.MinBinSize
        % Very low source count: Use global statistics
        warning('Very low source count (%d). Using global statistics.', N_Total);
        p5  = prctile(RMS_valid, 5);
        p25 = prctile(RMS_valid, 25);
        delta = max(p25 - p5, p5 * 0.05);
        cutoff = p25 + (Args.Tightness * delta);
        
        FinalOutlierFlag(valid_data) = RMS_valid > cutoff;
        DebugInfo = struct();
        return;
    end
    
    % --- STAGE 2: Define Adaptive Bins ---
    nBins = floor(N_Total / Args.MinBinSize);
    nBins = min(nBins, Args.MaxBins);
    nBins = max(nBins, 1);
    
    pct_edges = linspace(0, 100, nBins + 1);
    edges = prctile(Mag_valid, pct_edges);
    edges = unique(edges);
    
    % --- STAGE 3: Binning Loop ---
    m_centers = nan(length(edges)-1, 1);
    b_p5      = nan(length(edges)-1, 1);
    b_p25     = nan(length(edges)-1, 1);
    
    for i = 1:length(edges)-1
        if i == length(edges)-1
            mask = (Mag_valid >= edges(i)) & (Mag_valid <= edges(i+1));
        else
            mask = (Mag_valid >= edges(i)) & (Mag_valid < edges(i+1));
        end
        
        if sum(mask) >= 5
            val = RMS_valid(mask);
            m_centers(i) = median(Mag_valid(mask)); 
            b_p5(i)      = prctile(val, 5);
            b_p25(i)     = prctile(val, 25);
        end
    end
    
    % Remove NaN bins
    valid_bins = ~isnan(b_p5);
    m_centers = m_centers(valid_bins);
    b_p5 = b_p5(valid_bins);
    b_p25 = b_p25(valid_bins);
    
    % Handle interpolation logic based on bin count
    if length(m_centers) < 2
        % Only 1 bin possible? Use flat cutoff across all magnitudes
        if isempty(b_p5), b_p5=0; b_p25=1; end
        Curve_P5  = repmat(mean(b_p5), size(Mag_valid));
        Curve_P25 = repmat(mean(b_p25), size(Mag_valid));
    else
        % --- STAGE 4: Smooth & Interpolate (FIXED) ---
        
        % 1. Interpolate inside the range (returns NaN outside)
        Curve_P5  = interp1(m_centers, b_p5, Mag_valid, 'pchip', NaN);
        Curve_P25 = interp1(m_centers, b_p25, Mag_valid, 'pchip', NaN);
        
        % 2. Manually Clamp Extrapolation (The "Nearest" logic)
        % Left Edge
        Curve_P5(Mag_valid < m_centers(1)) = b_p5(1);
        Curve_P25(Mag_valid < m_centers(1)) = b_p25(1);
        
        % Right Edge
        Curve_P5(Mag_valid > m_centers(end)) = b_p5(end);
        Curve_P25(Mag_valid > m_centers(end)) = b_p25(end);
    end
    
    % --- STAGE 5: Strict Cutoff ---
    Delta = Curve_P25 - Curve_P5;
    Delta = max(Delta, Curve_P5 * 0.05); % Sanity floor
    
    Cutoff_Line = Curve_P25 + (Args.Tightness * Delta);
    
    FinalOutlierFlag(valid_data) = RMS_valid > Cutoff_Line;
    
    % --- Debug ---
    DebugInfo.CutoffLine = nan(size(RMS));
    DebugInfo.CutoffLine(valid_data) = Cutoff_Line;
    DebugInfo.BinCenters = m_centers;
    DebugInfo.BinP5 = b_p5;
    DebugInfo.BinP25 = b_p25;
end