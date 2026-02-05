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
    matchedCount = matchedCount + 1;
    if mod(matchedCount, 20) == 0, fprintf("Processed %d events...\n", matchedCount); end
end

% Save Tables
writetable(Tstats, fullfile(OutDirFull, "NullTest_Results_Full.csv"));
Tclean = Tstats(Tstats.fs > FsThreshold, :);
writetable(Tclean, fullfile(OutDirClean, "NullTest_Results_Clean.csv"));


%% ========================================================================
%  PART 2: PLOTTING FUNCTION
%  ========================================================================
plot_population(Tstats, OutDirFull, FsThreshold, true);   % All Events
plot_population(Tclean, OutDirClean, FsThreshold, false); % Clean Events

fprintf("Done. Check folders:\n  %s\n  %s\n", OutDirFull, OutDirClean);


% -------------------------------------------------------------------------
%  LOCAL FUNCTION: Plotting Logic
% -------------------------------------------------------------------------
function plot_population(T, OutDir, FsThresh, showBlended)

    % Identify Quality Groups
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

    % --- PLOT 1: Significance (Percentile vs DeltaChi2) ---
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

    % --- PLOT 3: ThetaE vs Percentile ---
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

    % --- PLOT 4: Limits Per Field (Split Plot with SAFER Margins) ---
    T = sortrows(T, 'TargetMag');
    if showBlended
        maskHigh = T.fs > FsThresh;
        maskLow  = T.fs <= FsThresh | isnan(T.fs);
    else
        maskHigh = true(height(T), 1);
        maskLow  = false(height(T), 1);
    end
    
    x_idx = 1:height(T);
    fig4 = figure('Color','w', 'Position', [100, 100, 1200, 800]); 
    
    % MARGINS CONFIGURATION:
    % Left = 0.15 (Space for Left Y-Label)
    % Width = 0.70 (Leaves 0.15 on the right for Right Y-Label)
    
    % Subplot 1: Theta E Limits (Top)
    subplot('Position', [0.15 0.40 0.70 0.52]); 
    yyaxis left
    hold on;
    y_floor = 0.5; % <--- CHANGED TO 0.5 as requested
    
    % Plot Noise Bars
    for i = 1:height(T)
        plot([i, i], [y_floor, T.Field_99_ThE(i)], '-', 'Color', [0.9 0.9 0.9], 'LineWidth', 4, 'HandleVisibility','off');
        plot([i-0.3, i+0.3], [T.Field_95_ThE(i), T.Field_95_ThE(i)], '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1, 'HandleVisibility','off');
    end
    p99 = plot(x_idx, T.Field_99_ThE, '-', 'Color', [0.5 0.5 0.5], 'LineWidth', 1.5, 'DisplayName', '99\% Noise Limit');
    p95 = plot(x_idx, T.Field_95_ThE, '--', 'Color', [0.6 0.6 0.6], 'LineWidth', 1.0, 'DisplayName', '95\% Noise Limit');
    
    % --- Markers Logic ---
    is_AboveNoise = T.Tgt_ThetaE > T.Field_99_ThE;
    is_Robust = T.Tgt_DChi2 > T.Field_99_DChi2;
    
    idx_BlueFilled = is_AboveNoise & is_Robust & maskHigh;
    if any(idx_BlueFilled)
        scatter(x_idx(idx_BlueFilled), T.Tgt_ThetaE(idx_BlueFilled), 100, 'b', ...
            'filled', 'MarkerEdgeColor', 'k', 'DisplayName', 'Robust Detection');
    end
    idx_BlueEmpty = is_AboveNoise & ~is_Robust & maskHigh;
    if any(idx_BlueEmpty)
        scatter(x_idx(idx_BlueEmpty), T.Tgt_ThetaE(idx_BlueEmpty), 100, 'w', ...
            'MarkerEdgeColor', 'b', 'LineWidth', 1.5, 'DisplayName', 'Marginal Detection');
    end
    if showBlended
        idx_RedFilled = is_AboveNoise & is_Robust & maskLow;
        if any(idx_RedFilled)
            scatter(x_idx(idx_RedFilled), T.Tgt_ThetaE(idx_RedFilled), 100, 'r', ...
                'filled', 'MarkerEdgeColor', 'k', 'MarkerFaceAlpha', 0.7, 'DisplayName', 'Robust Artifact');
        end
        idx_RedEmpty = is_AboveNoise & ~is_Robust & maskLow;
        if any(idx_RedEmpty)
            scatter(x_idx(idx_RedEmpty), T.Tgt_ThetaE(idx_RedEmpty), 100, 'w', ...
                'MarkerEdgeColor', 'r', 'LineWidth', 1.5, 'DisplayName', 'Marginal Artifact');
        end
    end
    
    % --- CHANGED: Bigger & Darker "Below Noise" Points ---
    idx_Below = ~is_AboveNoise;
    if any(idx_Below)
        scatter(x_idx(idx_Below), T.Tgt_ThetaE(idx_Below), 50, [0.3 0.3 0.3], ...
            'filled', 'MarkerFaceAlpha', 0.5, 'DisplayName', 'Below Noise');
    end
    
    set(gca, 'YScale', 'log', 'FontSize', 12, 'YColor', 'k', 'XTickLabel', []);
    ylabel('Fitted $$\theta_E$$ [mas]', 'FontSize', 12);
    xlim([0, height(T)+1]);
    current_ylim = [y_floor, max([T.Field_99_ThE; T.Tgt_ThetaE]) * 1.5];
    ylim(current_ylim);
    title('Astrometric Sensitivity per Field', 'FontSize', 14);
    legend([p99, p95], 'Location', 'northwest');
    grid on;

    % Right Axis (Mass)
    yyaxis right
    kappa = 8.144; Ds = 8.0; Dl_ref = 4.0; pi_rel = (1/Dl_ref - 1/Ds);
    M_min = (current_ylim(1)^2) / (kappa * pi_rel);
    M_max = (current_ylim(2)^2) / (kappa * pi_rel);
    set(gca, 'YScale', 'log', 'FontSize', 12, 'YColor', [0.4 0.4 0.4]);
    ylim([M_min, M_max]);
    ylabel(sprintf('Mass ($$D_L$$=%.0fkpc) [$$M_\\odot$$]', Dl_ref), 'FontSize', 12);
    
    % Subplot 2: Number of Sources (Bottom)
    % Position: Left=0.15, Bottom=0.10, Width=0.70, Height=0.20
    subplot('Position', [0.15 0.10 0.70 0.20]); 
    bar(x_idx, T.NumSources, 'FaceColor', [0.3 0.3 0.3], 'EdgeColor', 'none');
    xlim([0, height(T)+1]);
    ylabel('# Sources', 'FontSize', 12);
    xlabel('Events (Sorted by Brightness)', 'FontSize', 12);
    set(gca, 'FontSize', 12);
    grid on;
    
    exportgraphics(fig4, fullfile(OutDir, "Pop_ThetaE_Limits_per_Field_Log.pdf"), 'ContentType', 'vector');
    close(fig4);
    
    % --- PLOT 5: Sensitivity Curve (ThetaE) ---
    fig5 = figure('Color','w', 'Position', [100 100 900 600]); hold on;
    
    % Plot 99
    scatter(T.TargetMag, T.Field_99_ThE, 30, [0.4 0.4 0.4], 'filled', 'MarkerFaceAlpha', 0.3);
    [sortedMags, sortIdx] = sort(T.TargetMag);
    
    % Plot 95
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