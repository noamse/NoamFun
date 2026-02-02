%% Configuration
clear; clc; close all;

% --- Analysis Settings ---
FsThreshold = 0.9;   

% --- Paths ---
ExperimentStr = 'ogleANewOut';
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
    
    if sum(mask_sample) < 10, continue; end
    
    % Calc Stats
    Prc_DChi2  = (sum(Sample_DChi2 < Tgt_DChi2) / sum(mask_sample)) * 100;
    Limit_99_ThE = prctile(Sample_ThE, 99);
    Limit_99_DChi2 = prctile(Sample_DChi2, 99);
    
    % Store
    newRow = table();
    newRow.Event      = evName;
    newRow.fs         = target_fs;
    newRow.TargetMag  = Tgt_Mag;
    newRow.Tgt_DChi2  = Tgt_DChi2;
    newRow.Prc_DChi2  = Prc_DChi2;
    newRow.Field_99_DChi2 = Limit_99_DChi2;
    newRow.Tgt_ThetaE = Tgt_ThE;
    newRow.Field_99_ThE = Limit_99_ThE;
    
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
%  LOCAL FUNCTION: Plotting Logic (Latex $$ Support + Full/Empty Markers)
% -------------------------------------------------------------------------
function plot_population(T, OutDir, FsThresh, showBlended)

    % Identify Quality Groups (Color: Blue vs Red)
    if showBlended
        maskHigh = T.fs > FsThresh;
        maskLow  = T.fs <= FsThresh | isnan(T.fs);
        % Updated to use $$ for latex interpreter
        lblHigh = sprintf('High Quality ($$f_s > %.1f$$)', FsThresh);
        lblLow  = sprintf('Blended ($$f_s \\leq %.1f$$)', FsThresh);
    else
        maskHigh = true(height(T), 1);
        maskLow  = false(height(T), 1);
        lblHigh = 'Golden Sample Candidates';
        lblLow  = '';
    end

    % --- PLOT 1: Significance (Percentile vs DeltaChi2) ---
    fig1 = figure('Color','w', 'Position', [100 100 800 600]); hold on;
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
    yline(95, '--r', '95\%'); % Escaped % for latex safety if needed
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
    fig3 = figure('Color','w', 'Position', [100 100 800 600]); hold on;
    if any(maskLow)
        scatter(T.Tgt_ThetaE(maskLow), T.Prc_DChi2(maskLow), 60, [0.8 0.4 0.4], ...
            'filled', 'MarkerFaceAlpha', 0.6, 'DisplayName', lblLow);
    end
    if any(maskHigh)
        scatter(T.Tgt_ThetaE(maskHigh), T.Prc_DChi2(maskHigh), 60, 'b', ...
            'filled', 'MarkerEdgeColor','k', 'DisplayName', lblHigh);
    end
    yline(99, '-r', '99\%');
    
    xlabel('Fitted $$\theta_E$$ [mas]', 'FontSize', 12);
    ylabel('Significance Percentile (\%)', 'FontSize', 12);
    title('Physicality Check', 'FontSize', 14);
    
    grid on;
    set(gca, 'FontSize', 12);
    exportgraphics(fig3, fullfile(OutDir, "Pop_Percentile_vs_ThetaE.pdf"), 'ContentType', 'vector');
    close(fig3);

    % --- PLOT 4: Limits Per Field (Visual Distinction) ---
    T = sortrows(T, 'TargetMag');
    if showBlended
        maskHigh = T.fs > FsThresh;
        maskLow  = T.fs <= FsThresh | isnan(T.fs);
    else
        maskHigh = true(height(T), 1);
        maskLow  = false(height(T), 1);
    end
    
    x_idx = 1:height(T);
    fig4 = figure('Color','w', 'Position', [100, 100, 1200, 600]); 
    
    yyaxis left
    hold on;
    y_floor = 8e-1; 
    
    % Plot Noise Bars
    for i = 1:height(T)
        plot([i, i], [y_floor, T.Field_99_ThE(i)], '-', 'Color', [0.9 0.9 0.9], 'LineWidth', 4, 'HandleVisibility','off');
    end
    plot(x_idx, T.Field_99_ThE, '-', 'Color', [0.5 0.5 0.5], 'LineWidth', 1, 'DisplayName', '99\% Noise Limit');
    
    % --- LOGIC FOR MARKERS ---
    % 1. Position Filter: Must be above the ThetaE Limit to be colored
    is_AboveNoise = T.Tgt_ThetaE > T.Field_99_ThE;
    
    % 2. Shape Filter: Filled if DChi2 is significant, Empty if not
    is_Robust = T.Tgt_DChi2 > T.Field_99_DChi2;
    
    % GROUP 1: Robust High Quality (Blue Filled)
    idx_BlueFilled = is_AboveNoise & is_Robust & maskHigh;
    if any(idx_BlueFilled)
        scatter(x_idx(idx_BlueFilled), T.Tgt_ThetaE(idx_BlueFilled), 100, 'b', ...
            'filled', 'MarkerEdgeColor', 'k', 'DisplayName', 'Robust Detection');
    end
    
    % GROUP 2: Marginal High Quality (Blue Empty)
    idx_BlueEmpty = is_AboveNoise & ~is_Robust & maskHigh;
    if any(idx_BlueEmpty)
        scatter(x_idx(idx_BlueEmpty), T.Tgt_ThetaE(idx_BlueEmpty), 100, 'w', ...
            'MarkerEdgeColor', 'b', 'LineWidth', 1.5, 'DisplayName', 'Marginal Detection');
    end
    
    % GROUP 3: Robust Blended (Red Filled)
    if showBlended
        idx_RedFilled = is_AboveNoise & is_Robust & maskLow;
        if any(idx_RedFilled)
            scatter(x_idx(idx_RedFilled), T.Tgt_ThetaE(idx_RedFilled), 100, 'r', ...
                'filled', 'MarkerEdgeColor', 'k', 'MarkerFaceAlpha', 0.7, 'DisplayName', 'Robust Artifact');
        end
        
        % GROUP 4: Marginal Blended (Red Empty)
        idx_RedEmpty = is_AboveNoise & ~is_Robust & maskLow;
        if any(idx_RedEmpty)
            scatter(x_idx(idx_RedEmpty), T.Tgt_ThetaE(idx_RedEmpty), 100, 'w', ...
                'MarkerEdgeColor', 'r', 'LineWidth', 1.5, 'DisplayName', 'Marginal Artifact');
        end
    end
    
    % GROUP 5: Below Noise (Small Dots)
    idx_Below = ~is_AboveNoise;
    if any(idx_Below)
        scatter(x_idx(idx_Below), T.Tgt_ThetaE(idx_Below), 20, 'k', ...
            'filled', 'MarkerFaceAlpha', 0.2, 'DisplayName', 'Below Noise');
    end
    
    % Setup Left Axis
    set(gca, 'YScale', 'log', 'FontSize', 12, 'YColor', 'k');
    ylabel('Fitted $$\theta_E$$ [mas]', 'FontSize', 12);
    xlabel('Events (Sorted by Brightness)', 'FontSize', 12);
    xlim([0, height(T)+1]);
    
    current_ylim = [y_floor, max([T.Field_99_ThE; T.Tgt_ThetaE]) * 1.5];
    ylim(current_ylim);
    
    % --- RIGHT AXIS (MASS) ---
    yyaxis right
    kappa = 8.144; Ds = 8.0; Dl_ref = 4.0; pi_rel = (1/Dl_ref - 1/Ds);
    M_min = (current_ylim(1)^2) / (kappa * pi_rel);
    M_max = (current_ylim(2)^2) / (kappa * pi_rel);
    
    set(gca, 'YScale', 'log', 'FontSize', 12, 'YColor', [0.4 0.4 0.4]);
    ylim([M_min, M_max]);
    
    % Updated label with $$ and escaped backslashes for sprintf
    ylabel(sprintf('Approx. Mass ($$D_L$$=%.0fkpc) [$$M_\\odot$$]', Dl_ref), 'FontSize', 12);
    
    title('Astrometric Sensitivity per Field', 'FontSize', 14);
    legend('Location', 'best');
    grid on;
    
    exportgraphics(fig4, fullfile(OutDir, "Pop_ThetaE_Limits_per_Field_Log.pdf"), 'ContentType', 'vector');
    close(fig4);
    
    % --- PLOT 5: Sensitivity Curve (ThetaE) ---
    fig5 = figure('Color','w', 'Position', [100 100 800 600]); hold on;
    scatter(T.TargetMag, T.Field_99_ThE, 60, [0.4 0.4 0.4], 'filled', 'MarkerFaceAlpha', 0.5);
    
    [sortedMags, sortIdx] = sort(T.TargetMag);
    try
        smoothLimit = smoothdata(T.Field_99_ThE(sortIdx), 'gaussian', 10);
        plot(sortedMags, smoothLimit, 'r-', 'LineWidth', 3, 'DisplayName', 'Trend');
    catch
        smoothLimit = T.Field_99_ThE(sortIdx);
        plot(sortedMags, smoothLimit, 'r-', 'LineWidth', 1, 'DisplayName', 'Trend');
    end
    
    set(gca, 'YScale', 'log', 'FontSize', 12);
    xlabel('Target Magnitude (I)', 'FontSize', 12);
    ylabel('99\% Sensitivity Limit on $$\theta_E$$ [mas]', 'FontSize', 12);
    title('Astrometric Precision vs Magnitude', 'FontSize', 14);
    grid on;
    exportgraphics(fig5, fullfile(OutDir, "Pop_Sensitivity_vs_Mag_Log.pdf"), 'ContentType', 'vector');
    close(fig5);

    % --- PLOT 6: MASS SENSITIVITY LIMITS ---
    kappa = 8.144; Ds = 8.0; DL_vec = [1, 4, 6]; colors = {'b', 'g', 'm'};
    
    fig6 = figure('Color','w', 'Position', [100 100 800 600]); hold on;
    for i = 1:length(DL_vec)
        Dl = DL_vec(i);
        pi_rel = (1/Dl - 1/Ds);
        Mass_Limit = (smoothLimit.^2) ./ (kappa * pi_rel);
        plot(sortedMags, Mass_Limit, 'LineWidth', 2.5, ...
            'Color', colors{i}, 'DisplayName', sprintf('Lens at %.0f kpc', Dl));
    end
    set(gca, 'YScale', 'log', 'FontSize', 12);
    xlabel('Target Magnitude (I)', 'FontSize', 12);
    ylabel('Minimum Detectable Mass [$$M_\odot$$]', 'FontSize', 12);
    title('Mass Detection Sensitivity', 'FontSize', 14);
    grid on;
    legend('Location', 'best');
    ylim([min(Mass_Limit)*0.5, max(Mass_Limit)*2]); 
    exportgraphics(fig6, fullfile(OutDir, "Pop_Sensitivity_Mass_Log.pdf"), 'ContentType', 'vector');
    close(fig6);

end