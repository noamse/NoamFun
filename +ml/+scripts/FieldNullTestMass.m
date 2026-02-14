%% Configuration
clear; clc; close all;

% --- Analysis Settings ---
FsThreshold = 0.9;   

% --- Paths ---
ExperimentStr = 'ogleABelt';
ExpRoot = "/data4/KMT/data/Experiments/" + ExperimentStr;
CollectedDir = fullfile(ExpRoot, "collected_results");
PlotDirDest  = "/home/noamse/astro/KMT_ML/data/KMTNet/Experiments/" + ExperimentStr;
MasterCSV    = "/home/noamse/KMT/data/test/AstrometryField_Inspect_A.csv";

% --- Output Directories ---
OutDirFull = fullfile(PlotDirDest, "Analysis_NullTest");
if ~exist(OutDirFull, 'dir'), mkdir(OutDirFull); end

OutDirClean = fullfile(PlotDirDest, "Analysis_NullTest_Clean");
if ~exist(OutDirClean, 'dir'), mkdir(OutDirClean); end

% NEW: Directory for individual field plots
OutDirFields = fullfile(OutDirFull, "FieldPlots");
if ~exist(OutDirFields, 'dir'), mkdir(OutDirFields); end

% --- Helper for JSON reading ---
readJsonSafe = @(f) jsondecode(fileread(f));

% --- Load Master Table ---
if ~isfile(MasterCSV)
    error('Master CSV not found: %s', MasterCSV);
end
Ta = readtable(MasterCSV);
Ta.event = compose("kmt%d_%02d", Ta.NumID, Ta.FieldID);
eventTa = Ta.event; IndTa = Ta.EventInd;

% --- Find Event Directories ---
eventDirs = dir(fullfile(CollectedDir, "kmt*"));
eventDirs = eventDirs([eventDirs.isdir]);

if isempty(eventDirs), fprintf("No directories found.\n"); return; end

% --- Storage ---
Tstats = table();
Global_Background_DChi2 = []; % Accumulator for ALL background sources

%% ========================================================================
%  PART 1: DATA COLLECTION
%  =======================================================================
fprintf('Starting Data Collection...\n');
matchedCount = 0;
ExtraMagSelect = 0.2;

for k = 1:numel(eventDirs)
    evName = string(eventDirs(k).name);
    evDir  = fullfile(eventDirs(k).folder, evName);
    
    % Match Target
    idx = find(eventTa == evName, 1, "first");
    if isempty(idx), continue; end
    TargetID = IndTa(idx);
    
    % Get fs
    target_fs = NaN; 
    plxJson = dir(fullfile(evDir, "params_photo-aux_*plx*.json"));
    if ~isempty(plxJson)
        try
            S = readJsonSafe(fullfile(plxJson(1).folder, plxJson(1).name));
            if isfield(S, 'fs'), target_fs = S.fs; end
        catch
        end
    end
    
    % Load Astrometry
    resPath = fullfile(evDir, "collected_astrometry_params.csv");
    if ~isfile(resPath)
        resFiles = dir(fullfile(evDir, "results_*.csv"));
        if isempty(resFiles), continue; end
        [~, newestIdx] = max([resFiles.datenum]);
        resPath = fullfile(resFiles(newestIdx).folder, resFiles(newestIdx).name);
    end
    Tres = readtable(resPath);
    
    % Find Target Row
    if iscell(Tres.source_id), Tres.source_id = str2double(Tres.source_id); end
    if ismember('source_id', Tres.Properties.VariableNames)
        Row = find(Tres.source_id == TargetID, 1, 'first');
    elseif ismember('starno', Tres.Properties.VariableNames)
        Row = find(Tres.starno == TargetID, 1, 'first');
    else, continue; end
    if isempty(Row), continue; end
    
    % Get Columns
    MagCol = Tres.mag_median; if isempty(MagCol), MagCol = Tres.mag0; end
    if ismember('chi2_unlensed', Tres.Properties.VariableNames)
        DChi2Col = Tres.chi2_unlensed - Tres.chi2;
    else, continue; end
    ThetaECol = Tres.thetaE;
    
    % Null Test Logic
    Tgt_Mag   = MagCol(Row);
    Tgt_DChi2 = DChi2Col(Row);
    Tgt_ThE   = ThetaECol(Row);
    
    mask_sample = (MagCol <= Tgt_Mag + ExtraMagSelect) & (1:height(Tres))' ~= Row & (ThetaECol > 0);
    Sample_ThE   = ThetaECol(mask_sample);
    Sample_DChi2 = DChi2Col(mask_sample);
    
    % --- Accumulate Background Stats (for global histogram) ---
    Global_Background_DChi2 = [Global_Background_DChi2; Sample_DChi2];
    
    nSources = sum(mask_sample); % Count sources
    if nSources < 10, continue; end
    
    % Calc Stats (99% AND 95%)
    Prc_DChi2  = (sum(Sample_DChi2 < Tgt_DChi2) / sum(mask_sample)) * 100;
    
    Limit_99_ThE = prctile(Sample_ThE, 99);
    Limit_95_ThE = prctile(Sample_ThE, 95); 
    
    Limit_99_DChi2 = prctile(Sample_DChi2, 99);
    Limit_95_DChi2 = prctile(Sample_DChi2, 95); 
    
    % Store
    newRow = table();
    newRow.Event      = evName;
    newRow.fs         = target_fs;
    newRow.TargetMag  = Tgt_Mag;
    newRow.NumSources = nSources; % Store Count
    
    newRow.Tgt_DChi2  = Tgt_DChi2;
    newRow.Prc_DChi2  = Prc_DChi2;
    newRow.Field_99_DChi2 = Limit_99_DChi2;
    newRow.Field_95_DChi2 = Limit_95_DChi2;
    
    newRow.Tgt_ThetaE = Tgt_ThE;
    newRow.Field_99_ThE = Limit_99_ThE;
    newRow.Field_95_ThE = Limit_95_ThE;
    
    Tstats = [Tstats; newRow];
    
    % =====================================================================
    % SETUP FIELD DIRECTORY
    % =====================================================================
    CurrentFieldDir = fullfile(OutDirFields, evName);
    if ~exist(CurrentFieldDir, 'dir'), mkdir(CurrentFieldDir); end

    % =====================================================================
    % FIELD PLOT 1: Scatter (ThetaE vs DChi2)
    % =====================================================================
    figField = figure('Visible', 'off', 'Position', [100, 100, 800, 600]);
    
    scatter(Sample_DChi2, Sample_ThE, 30, 'k', 'filled', ...
        'MarkerFaceAlpha', 0.3, 'DisplayName', 'Background Sources'); 
    hold on;
    scatter(Tgt_DChi2, Tgt_ThE, 120, 'r', 'filled', ...
        'MarkerEdgeColor', 'k', 'DisplayName', 'Event Target');
    xline(Limit_99_DChi2, 'r--', 'LineWidth', 1.5, 'DisplayName', '99% Significance');
    yline(Limit_99_ThE, 'b--', 'LineWidth', 1.5, 'DisplayName', '99% Amplitude');
    
    set(gca, 'XScale', 'log', 'YScale', 'log', 'FontSize', 12);
    xlabel('\Delta\chi^2 (Significance)', 'FontSize', 14);
    ylabel('\theta_E [mas] (Amplitude)', 'FontSize', 14);
    title(sprintf('%s (Mag=%.2f, fs=%.2f)', evName, Tgt_Mag, target_fs), 'Interpreter', 'none');
    legend('Location', 'best');
    grid on;
    
    % Robust Limits
    valid_chi2 = Sample_DChi2(Sample_DChi2 > 0);
    valid_the  = Sample_ThE(Sample_ThE > 0);
    if isempty(valid_chi2), valid_chi2 = 0.1; end
    if isempty(valid_the), valid_the = 0.1; end
    
    t_chi = Tgt_DChi2; if isnan(t_chi) || t_chi <= 0, t_chi = Limit_99_DChi2; end
    t_the = Tgt_ThE;   if isnan(t_the) || t_the <= 0, t_the = Limit_99_ThE; end
    l_chi = Limit_99_DChi2; if isnan(l_chi) || l_chi <= 0, l_chi = 1; end
    l_the = Limit_99_ThE;   if isnan(l_the) || l_the <= 0, l_the = 1; end
    
    min_x = min([t_chi, l_chi]) / 5;
    max_x = max([t_chi, l_chi, max(valid_chi2)]) * 1.5;
    min_y = min([t_the, l_the]) / 10;
    max_y = max([t_the, l_the, max(valid_the)]) * 1.5;
    
    if min_x < 1e-2, min_x = 1e-2; end
    if min_y < 1e-2, min_y = 1e-2; end 
    if max_x <= min_x, max_x = min_x * 10; end
    if max_y <= min_y, max_y = min_y * 10; end
    
    xlim([min_x, max_x]);
    ylim([min_y, max_y]);
    
    saveNameScatter = fullfile(CurrentFieldDir, evName + "_Scatter_ThetaE_vs_DChi2.png");
    exportgraphics(figField, saveNameScatter);
    close(figField);

    % =====================================================================
    % FIELD PLOT 2a: Histogram - Delta Chi2 (Log Scale)
    % =====================================================================
    figHistChi = figure('Visible', 'off', 'Position', [100, 100, 600, 500]);
    
    histogram(Sample_DChi2, 15, 'FaceColor', [0.7 0.7 0.7], 'EdgeColor', 'k'); hold on;
    xline(Tgt_DChi2, 'r-', 'LineWidth', 2, 'Label', 'Target');
    xline(Limit_99_DChi2, 'b--', 'LineWidth', 1.5, 'Label', '99% Limit');
    
    xlabel('\Delta\chi^2', 'FontSize', 12);
    ylabel('N Sources', 'FontSize', 12);
    title(sprintf('%s: Significance Distribution', evName), 'Interpreter', 'none', 'FontSize', 13);
    grid on;
    
    % FORCE LOG SCALE FOR DCHI2
    set(gca, 'XScale', 'log'); 

    saveNameHistChi = fullfile(CurrentFieldDir, evName + "_Hist_DChi2.png");
    exportgraphics(figHistChi, saveNameHistChi);
    close(figHistChi);

    % =====================================================================
    % FIELD PLOT 2b: Histogram - ThetaE (Linear Scale)
    % =====================================================================
    figHistTheta = figure('Visible', 'off', 'Position', [100, 100, 600, 500]);
    
    histogram(Sample_ThE, 15, 'FaceColor', [0.7 0.7 0.7], 'EdgeColor', 'k'); hold on;
    xline(Tgt_ThE, 'r-', 'LineWidth', 2, 'Label', 'Target');
    xline(Limit_99_ThE, 'b--', 'LineWidth', 1.5, 'Label', '99% Limit');
    
    xlabel('\theta_E [mas]', 'FontSize', 12);
    ylabel('N Sources', 'FontSize', 12);
    title(sprintf('%s: Amplitude Distribution', evName), 'Interpreter', 'none', 'FontSize', 13);
    grid on;
    
    % FORCE LINEAR SCALE FOR THETAE (Default is linear, explicitly ensuring it)
    set(gca, 'XScale', 'linear'); 

    saveNameHistTheta = fullfile(CurrentFieldDir, evName + "_Hist_ThetaE.png");
    exportgraphics(figHistTheta, saveNameHistTheta);
    close(figHistTheta);
    % =====================================================================
    
    matchedCount = matchedCount + 1;
    if mod(matchedCount, 20) == 0, fprintf("Processed %d events...\n", matchedCount); end
end

% Save CSVs
writetable(Tstats, fullfile(OutDirFull, "NullTest_Results_Full.csv"));
Tclean = Tstats(Tstats.fs > FsThreshold, :);
writetable(Tclean, fullfile(OutDirClean, "NullTest_Results_Clean.csv"));

%% ========================================================================
%  PART 2: ROBUST CANDIDATES & GLOBAL STATS
%  ========================================================================

mask_HighQuality = Tstats.fs > FsThreshold;
mask_AboveNoise  = Tstats.Tgt_ThetaE > Tstats.Field_99_ThE;
mask_Significant = Tstats.Tgt_DChi2 > Tstats.Field_99_DChi2;

RobustCandidates = Tstats(mask_HighQuality & mask_AboveNoise & mask_Significant, :);

fprintf('\n\n================================================================\n');
fprintf('  NEW TABLE CREATED: "RobustCandidates" (%d events)\n', height(RobustCandidates));
fprintf('================================================================\n');
disp(RobustCandidates);


% ========================================================================
%  Global Histograms (Target Dist)
% ========================================================================
figHistTargets = figure('Color','w', 'Position', [100, 100, 1000, 500]);

subplot(1, 2, 1);
histogram(Tstats.Tgt_DChi2, 20, 'FaceColor', 'b', 'EdgeColor', 'k', 'FaceAlpha', 0.6);
hold on;
xline(median(Global_Background_DChi2), 'k--', 'LineWidth', 1.5, 'Label', 'Bkg Median');
xlabel('Target $$\Delta\chi^2$$', 'FontSize', 12, 'Interpreter', 'latex');
ylabel('Count', 'FontSize', 12);
title('Distribution of Target Significance', 'FontSize', 14);
set(gca, 'YScale', 'log', 'XScale', 'log'); 
grid on;

subplot(1, 2, 2);
histogram(Tstats.Tgt_ThetaE, 20, 'FaceColor', 'r', 'EdgeColor', 'k', 'FaceAlpha', 0.6);
xlabel('Target $$\theta_E$$ [mas]', 'FontSize', 12, 'Interpreter', 'latex');
ylabel('Count', 'FontSize', 12);
title('Distribution of Target Amplitude', 'FontSize', 14);
set(gca, 'YScale', 'log', 'XScale', 'log');
grid on;

exportgraphics(figHistTargets, fullfile(OutDirFull, "Pop_Histograms_Targets.pdf"), 'ContentType', 'vector');


% ========================================================================
%  Global Null Distribution
% ========================================================================
figGlobalNull = figure('Color','w', 'Position', [150, 150, 800, 600]);

Clean_Bkg_DChi2 = Global_Background_DChi2(isfinite(Global_Background_DChi2));

histogram(Clean_Bkg_DChi2, 'Normalization', 'pdf', 'EdgeColor', 'none', 'FaceColor', [0.4 0.4 0.4]);
hold on;

xline(prctile(Clean_Bkg_DChi2, 99), 'r--', 'LineWidth', 2, 'Label', '99\% Global Limit');
xline(prctile(Clean_Bkg_DChi2, 99.9), 'r-', 'LineWidth', 2, 'Label', '99.9\% Global Limit');

xlabel('Background Source $$\Delta\chi^2$$', 'FontSize', 14, 'Interpreter', 'latex');
ylabel('Probability Density', 'FontSize', 14);
title(sprintf('Global Null Distribution (N=%d Background Sources)', length(Clean_Bkg_DChi2)), 'FontSize', 16);
set(gca, 'YScale', 'log', 'XScale', 'log', 'FontSize', 12);
grid on;
xlim([min(Clean_Bkg_DChi2(Clean_Bkg_DChi2>0)), max(Clean_Bkg_DChi2)*1.5]);

exportgraphics(figGlobalNull, fullfile(OutDirFull, "Global_Null_Distribution_DChi2.pdf"), 'ContentType', 'vector');


%% ========================================================================
%  PART 3: PLOTTING FUNCTION (Existing)
%  ========================================================================
plot_population(Tstats, OutDirFull, FsThreshold, true);   % All Events
plot_population(Tclean, OutDirClean, FsThreshold, false); % Clean Events

fprintf("Done. Check folders:\n  %s\n  %s\n  %s\n", OutDirFull, OutDirClean, OutDirFields);


% -------------------------------------------------------------------------
%  LOCAL FUNCTION: Plotting Logic
% -------------------------------------------------------------------------
function plot_population(T, OutDir, FsThresh, showBlended)
    if showBlended
        maskHigh = T.fs > FsThresh;
        maskLow  = T.fs <= FsThresh | isnan(T.fs);
        lblHigh = sprintf('High Quality ($$f_s > %.1f$$)', FsThresh);
        lblLow  = sprintf('Blended ($$f_s \\leq %.1f$$)', FsThresh);
    else
        maskHigh = true(height(T), 1);
        maskLow  = false(height(T), 1);
        lblHigh = 'Golden Sample Candidates';
        lblLow  = '';
    end

    % Plot 1
    fig1 = figure('Color','w', 'Position', [100 100 900 600]); hold on;
    if any(maskLow)
        scatter(T.Tgt_DChi2(maskLow), T.Prc_DChi2(maskLow), 50, ...
            'filled', 'MarkerFaceColor', [0.8 0.4 0.4], 'MarkerEdgeColor','none', ...
            'MarkerFaceAlpha', 0.6, 'DisplayName', lblLow);
    end
    if any(maskHigh)
        scatter(T.Tgt_DChi2(maskHigh), T.Prc_DChi2(maskHigh), 80, ...
            'filled', 'MarkerFaceColor', 'b', 'MarkerEdgeColor','k', ...
            'DisplayName', lblHigh);
    end
    yline(95, '--r', '95\%'); 
    yline(99, '-r', '99\%');
    xlabel('Target $$\Delta\chi^2$$', 'FontSize', 12);
    ylabel('Percentile in Local Field (\%)', 'FontSize', 12);
    title('Detection Significance', 'FontSize', 14);
    set(gca, 'XScale', 'log', 'FontSize', 12);
    grid on; ylim([0 105]);
    legend('Location','best');
    exportgraphics(fig1, fullfile(OutDir, "Pop_Percentile_vs_DChi2.pdf"), 'ContentType', 'vector');
    close(fig1);

    % Plot 3
    fig3 = figure('Color','w', 'Position', [100 100 900 600]); hold on;
    if any(maskLow)
        scatter(T.Tgt_ThetaE(maskLow), T.Prc_DChi2(maskLow), 60, [0.8 0.4 0.4], ...
            'filled', 'MarkerFaceAlpha', 0.6, 'DisplayName', lblLow);
    end
    if any(maskHigh)
        scatter(T.Tgt_ThetaE(maskHigh), T.Prc_DChi2(maskHigh), 60, 'b', ...
            'filled', 'MarkerEdgeColor','k', 'DisplayName', lblHigh);
    end
    yline(95, '--r', '95\%');
    yline(99, '-r', '99\%');
    xlabel('Fitted $$\theta_E$$ [mas]', 'FontSize', 12);
    ylabel('Significance Percentile (\%)', 'FontSize', 12);
    title('Physicality Check', 'FontSize', 14);
    grid on;
    set(gca, 'FontSize', 12);
    exportgraphics(fig3, fullfile(OutDir, "Pop_Percentile_vs_ThetaE.pdf"), 'ContentType', 'vector');
    close(fig3);

    % Plot 4
    T = sortrows(T, 'TargetMag');
    x_idx = 1:height(T);
    fig4 = figure('Color','w', 'Position', [100, 100, 1200, 800]); 
    subplot('Position', [0.15 0.40 0.70 0.52]); 
    yyaxis left; hold on; y_floor = 0.5; 
    for i = 1:height(T)
        plot([i, i], [y_floor, T.Field_99_ThE(i)], '-', 'Color', [0.9 0.9 0.9], 'LineWidth', 4, 'HandleVisibility','off');
        plot([i-0.3, i+0.3], [T.Field_95_ThE(i), T.Field_95_ThE(i)], '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1, 'HandleVisibility','off');
    end
    p99 = plot(x_idx, T.Field_99_ThE, '-', 'Color', [0.5 0.5 0.5], 'LineWidth', 1.5, 'DisplayName', '99\% Noise Limit');
    p95 = plot(x_idx, T.Field_95_ThE, '--', 'Color', [0.6 0.6 0.6], 'LineWidth', 1.0, 'DisplayName', '95\% Noise Limit');
    
    is_AboveNoise_Sorted = T.Tgt_ThetaE > T.Field_99_ThE;
    is_Robust_Sorted = T.Tgt_DChi2 > T.Field_99_DChi2;
    if showBlended
         maskHigh_Sorted = T.fs > FsThresh;
         maskLow_Sorted  = T.fs <= FsThresh | isnan(T.fs);
    else
         maskHigh_Sorted = true(height(T), 1);
         maskLow_Sorted  = false(height(T), 1);
    end
    idx_BlueFilled_Sorted = is_AboveNoise_Sorted & is_Robust_Sorted & maskHigh_Sorted;
    if any(idx_BlueFilled_Sorted)
        scatter(x_idx(idx_BlueFilled_Sorted), T.Tgt_ThetaE(idx_BlueFilled_Sorted), 100, 'b', ...
            'filled', 'MarkerEdgeColor', 'k', 'DisplayName', 'Robust Detection');
    end
    idx_BlueEmpty_Sorted = is_AboveNoise_Sorted & ~is_Robust_Sorted & maskHigh_Sorted;
    if any(idx_BlueEmpty_Sorted)
        scatter(x_idx(idx_BlueEmpty_Sorted), T.Tgt_ThetaE(idx_BlueEmpty_Sorted), 100, 'w', ...
            'MarkerEdgeColor', 'b', 'LineWidth', 1.5, 'DisplayName', 'Marginal Detection');
    end
    if showBlended
        idx_RedFilled_Sorted = is_AboveNoise_Sorted & is_Robust_Sorted & maskLow_Sorted;
        if any(idx_RedFilled_Sorted)
            scatter(x_idx(idx_RedFilled_Sorted), T.Tgt_ThetaE(idx_RedFilled_Sorted), 100, 'r', ...
                'filled', 'MarkerEdgeColor', 'k', 'MarkerFaceAlpha', 0.7, 'DisplayName', 'Robust Artifact');
        end
        idx_RedEmpty_Sorted = is_AboveNoise_Sorted & ~is_Robust_Sorted & maskLow_Sorted;
        if any(idx_RedEmpty_Sorted)
            scatter(x_idx(idx_RedEmpty_Sorted), T.Tgt_ThetaE(idx_RedEmpty_Sorted), 100, 'w', ...
                'MarkerEdgeColor', 'r', 'LineWidth', 1.5, 'DisplayName', 'Marginal Artifact');
        end
    end
    idx_Below_Sorted = ~is_AboveNoise_Sorted;
    if any(idx_Below_Sorted)
        scatter(x_idx(idx_Below_Sorted), T.Tgt_ThetaE(idx_Below_Sorted), 50, [0.3 0.3 0.3], ...
            'filled', 'MarkerFaceAlpha', 0.5, 'DisplayName', 'Below Noise');
    end
    set(gca, 'YScale', 'log', 'FontSize', 12, 'YColor', 'k', 'XTickLabel', []);
    ylabel('Fitted $$\theta_E$$ [mas]', 'FontSize', 12);
    xlim([0, height(T)+1]);
    ylim([y_floor, max([T.Field_99_ThE; T.Tgt_ThetaE]) * 1.5]);
    title('Astrometric Sensitivity per Field', 'FontSize', 14);
    legend([p99, p95], 'Location', 'northwest');
    grid on;
    yyaxis right
    kappa = 8.144; Ds = 8.0; Dl_ref = 4.0; pi_rel = (1/Dl_ref - 1/Ds);
    M_min = (y_floor^2) / (kappa * pi_rel);
    M_max = (max([T.Field_99_ThE; T.Tgt_ThetaE]) * 1.5)^2 / (kappa * pi_rel);
    set(gca, 'YScale', 'log', 'FontSize', 12, 'YColor', [0.4 0.4 0.4]);
    ylim([M_min, M_max]);
    ylabel(sprintf('Mass ($$D_L$$=%.0fkpc) [$$M_\\odot$$]', Dl_ref), 'FontSize', 12);
    
    subplot('Position', [0.15 0.10 0.70 0.20]); 
    bar(x_idx, T.NumSources, 'FaceColor', [0.3 0.3 0.3], 'EdgeColor', 'none');
    xlim([0, height(T)+1]);
    ylabel('# Sources', 'FontSize', 12);
    xlabel('Events (Sorted by Brightness)', 'FontSize', 12);
    set(gca, 'FontSize', 12);
    grid on;
    exportgraphics(fig4, fullfile(OutDir, "Pop_ThetaE_Limits_per_Field_Log.pdf"), 'ContentType', 'vector');
    close(fig4);
    
    % Plot 5
    fig5 = figure('Color','w', 'Position', [100 100 900 600]); hold on;
    scatter(T.TargetMag, T.Field_99_ThE, 30, [0.4 0.4 0.4], 'filled', 'MarkerFaceAlpha', 0.3);
    [sortedMags, sortIdx] = sort(T.TargetMag);
    scatter(T.TargetMag, T.Field_95_ThE, 30, [0.6 0.6 0.6], 'filled', 'MarkerFaceAlpha', 0.3, 'HandleVisibility','off');
    try
        smoothLimit99 = smoothdata(T.Field_99_ThE(sortIdx), 'gaussian', 10);
        smoothLimit95 = smoothdata(T.Field_95_ThE(sortIdx), 'gaussian', 10);
        plot(sortedMags, smoothLimit99, 'r-', 'LineWidth', 2, 'DisplayName', '99\% Limit');
        plot(sortedMags, smoothLimit95, 'r--', 'LineWidth', 1.5, 'DisplayName', '95\% Limit');
    catch
        plot(sortedMags, T.Field_99_ThE(sortIdx), 'r-', 'LineWidth', 1);
    end
    set(gca, 'YScale', 'log', 'FontSize', 12);
    xlabel('Target Magnitude (I)', 'FontSize', 12);
    ylabel('Sensitivity Limit on $$\theta_E$$ [mas]', 'FontSize', 12);
    title('Astrometric Precision vs Magnitude', 'FontSize', 14);
    grid on; legend('Location','best');
    exportgraphics(fig5, fullfile(OutDir, "Pop_Sensitivity_vs_Mag_Log.pdf"), 'ContentType', 'vector');
    close(fig5);
end