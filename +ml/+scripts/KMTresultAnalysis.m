%% Configuration
clear; clc; close all;

% --- Paths ---
ExperimentStr = 'ogleABelt';
ExpRoot = "/data4/KMT/data/Experiments/" + ExperimentStr;
CollectedDir = fullfile(ExpRoot, "collected_results");
PlotDirDest  = "/home/noamse/astro/KMT_ML/data/KMTNet/Experiments/" + ExperimentStr;
MasterCSV    = "/home/noamse/KMT/data/test/AstrometryField_Inspect_A.csv";
OGLE_ROOT    = '/home/noamse/KMT/OGLELC';

% --- Load Master Table ---
if ~isfile(MasterCSV)
    error('Master CSV not found: %s', MasterCSV);
end
Ta = readtable(MasterCSV);

% Construct event names (kmtXXXXXX_XX)
Ta.event = strcat("kmt", string(Ta.NumID), "_", compose("%02d", Ta.FieldID));
eventTa = Ta.event;
IndTa   = Ta.EventInd;

% --- Find Event Directories ---
eventDirs = dir(fullfile(CollectedDir, "kmt*"));
eventDirs = eventDirs([eventDirs.isdir]);

fprintf("Found %d event directories in %s\n", numel(eventDirs), CollectedDir);
if isempty(eventDirs), return; end

% --- Helper for JSON reading ---
readJsonSafe = @(f) jsondecode(fileread(f));

% --- Storage for Population Data ---
TphoPlx = table();
TphoStd = table();

matchedCount = 0;

%% Loop over Events
for k = 1:numel(eventDirs)
    
    evName = string(eventDirs(k).name);
    evDir  = fullfile(eventDirs(k).folder, evName);
    
    % 1. Match to Master Table
    idx = find(eventTa == evName, 1, "first");
    if isempty(idx)
        continue;
    end
    TargetID = IndTa(idx);
    
    % 2. Find Astrometry CSV (The one created by collect_results.py)
    resPath = fullfile(evDir, "collected_astrometry_params.csv");
    
    if ~isfile(resPath)
        % Fallback for old style results_*.csv if new one isn't there yet
        resFiles = dir(fullfile(evDir, "results_*.csv"));
        if isempty(resFiles)
            continue;
        end
        [~, newestIdx] = max([resFiles.datenum]);
        resPath = fullfile(resFiles(newestIdx).folder, resFiles(newestIdx).name);
    end
    
    Tres = readtable(resPath);
    
    % Find target row
    % Ensure Source ID column is handled correctly (it might be string or double)
    if iscell(Tres.source_id)
        Tres.source_id = str2double(Tres.source_id);
    end
    % Support both 'source_id' (new) and 'starno' (old) column names
    if ismember('source_id', Tres.Properties.VariableNames)
        EventIndRow = find(Tres.source_id == TargetID, 1, 'first');
    elseif ismember('starno', Tres.Properties.VariableNames)
        EventIndRow = find(Tres.starno == TargetID, 1, 'first');
    else
        continue;
    end
    
    if isempty(EventIndRow)
        continue;
    end
    
    % Determine Magnitude Data (X-Axis)
    if ismember('mag_median', Tres.Properties.VariableNames)
        MagData = Tres.mag_median;
        XLabelStr = 'Median Magnitude';
    else
        % Fallback to mag0 if mag_median isn't calculated yet
        MagData = Tres.mag0;
        XLabelStr = 'mag0';
    end

    % Calculate Delta Chi2
    if ismember('chi2_unlensed', Tres.Properties.VariableNames)
        DeltaChi2 = Tres.chi2_unlensed - Tres.chi2;
    else
        DeltaChi2 = nan(height(Tres), 1);
    end
    
    % Prepare Errors
    if ismember('thetaE_err', Tres.Properties.VariableNames)
        ThetaE_Err = abs(Tres.thetaE_err);
    else
        ThetaE_Err = zeros(height(Tres), 1);
    end
    
    % 3. Load Photometry JSONs (Standard logic...)
    phot_std  = [];
    phot_plx  = [];
    
    stdJson  = dir(fullfile(evDir, "params_photo-aux_*std*.json"));
    plxJson  = dir(fullfile(evDir, "params_photo-aux_*plx*.json"));
    
    if ~isempty(stdJson)
        try
            S = readJsonSafe(fullfile(stdJson(1).folder, stdJson(1).name));
            phot_std = S;
            TevStd = struct2table(S, "AsArray", true);
            TevStd.event = evName;
            TphoStd = [TphoStd; TevStd];
        catch
        end
    end
    
    if ~isempty(plxJson)
        try
            S = readJsonSafe(fullfile(plxJson(1).folder, plxJson(1).name));
            phot_plx = S;
            TevPlx = struct2table(S, "AsArray", true);
            TevPlx.event = evName;
            TphoPlx = [TphoPlx; TevPlx];
        catch
        end
    end
    
    matchedCount = matchedCount + 1;
    
    % ============================================================
    %  PLOTTING: PER EVENT
    % ============================================================
    
    outDirPlot = fullfile(PlotDirDest, "plots_summary", evName);
    if ~exist(outDirPlot, "dir"), mkdir(outDirPlot); end
    
    % Copy Images
    pngList = ["lc_aux-phot_WIS-1.png", "aux_fit_diagnostic.png"];
    for ip = 1:numel(pngList)
        srcP = fullfile(evDir, pngList(ip));
        if isfile(srcP)
            copyfile(srcP, fullfile(outDirPlot, pngList(ip)));
        end
    end
    
    % --- Figure 1: ThetaE vs Median Mag & DeltaChi2 vs Median Mag ---
    fig1 = figure('Color','w','Name', char(evName), 'Visible', 'off');
    tiledlayout(2,1,'Padding','compact','TileSpacing','compact');
    
    % Subplot 1: ThetaE vs Mag
    nexttile;
    hold on;
    
    % Field Stars (Transparent)
    e1 = errorbar(MagData, Tres.thetaE, ThetaE_Err, '.', ...
        'MarkerSize', 12, 'Color', [0.7, 0.5, 0.5], 'CapSize', 0);
    e1.Color(4) = 0.4; 
    
    % Target Star (Bold)
    errorbar(MagData(EventIndRow), Tres.thetaE(EventIndRow), ThetaE_Err(EventIndRow), 'd', ...
        'MarkerSize', 8, 'MarkerFaceColor', 'k', 'MarkerEdgeColor', 'k', ...
        'Color', 'k', 'CapSize', 4, 'LineWidth', 1.5);
        
    %set(gca, 'YScale', 'log');
    %set(gca, 'XDir', 'reverse'); % Brighter stars left
    ylabel('$\theta_E$', 'Interpreter','latex');
    xlabel(XLabelStr); 
    grid on;
    
    % Subplot 2: Delta Chi2 vs Mag
    nexttile;
    hold on;
    semilogy(MagData, DeltaChi2, '.', 'MarkerSize', 15, 'Color',[0.7,0.5,0.5]); 
    semilogy(MagData(EventIndRow), DeltaChi2(EventIndRow), 'd', ...
        'MarkerSize', 8, 'MarkerFaceColor', 'k', 'MarkerEdgeColor', 'k');
    
    %set(gca, 'XDir', 'reverse');
    xlabel(XLabelStr); 
    ylabel('$\Delta \chi^2$', 'Interpreter','latex'); 
    grid on;
    
    
    exportgraphics(fig1, fullfile(outDirPlot, evName + "__thetaE_Dchi2.pdf"));
    close(fig1);
    
    % --- Figure 2: Histogram (Same as before) ---
    fig2 = figure('Color','w','Visible', 'off');
    h = histogram(DeltaChi2, 20); hold on;
    val = DeltaChi2(EventIndRow);
    if ~isnan(val)
        plot([val, val], [0, max(h.Values)], '--k', 'LineWidth', 2);
    end
    xlabel('$\Delta \chi^2$', 'Interpreter','latex'); ylabel('Count'); title(char(evName), 'Interpreter', 'none');
    exportgraphics(fig2, fullfile(outDirPlot, evName + "__Dchi2_hist.pdf"));
    close(fig2);
    
    fprintf("Processed %s\n", evName);
end

fprintf('\nMatched and processed %d / %d events.\n', matchedCount, numel(eventDirs));

%% ... (Population plotting section remains unchanged) ...
if isempty(TphoPlx) || isempty(TphoStd)
    fprintf("Insufficient data for population plots.\n");
    return;
end

% 1. Sync Tables
[~, idxStd, idxPlx] = intersect(TphoStd.event, TphoPlx.event, 'stable');
Tstd_sync = TphoStd(idxStd, :);
Tplx_sync = TphoPlx(idxPlx, :);

n = height(Tplx_sync);
hasOGLE = false(n,1);

% 2. Check OGLE Availability
for i = 1:n
    ev = string(Tplx_sync.event(i));
    baseEv = extractBefore(ev, '_'); 
    ogleEvDir = fullfile(OGLE_ROOT, baseEv);
    if isfolder(ogleEvDir)
        d = dir(fullfile(ogleEvDir, '**', '*phot.dat'));
        if isempty(d), d = dir(fullfile(ogleEvDir, '**', '*.dat')); end
        if ~isempty(d), hasOGLE(i) = true; end
    end
end

%% 3. Calculate Metrics
DeltaChi2_Phot = Tstd_sync.chi2 - Tplx_sync.chi2;
DeltaChi2_Phot(DeltaChi2_Phot < 0) = nan;
DeltaChi2_Phot(DeltaChi2_Phot > 300) = 300;
DeltaChi2_Phot(DeltaChi2_Phot <= 0.2) = 0;

piE = sqrt(Tplx_sync.piEN.^2 + Tplx_sync.piEE.^2);
piEE_abs = abs(Tplx_sync.piEE);
fs  = Tplx_sync.fs;
tE  = Tplx_sync.tE;
PiEFlag = 0.7;

% 4. Categorize
FlagA = DeltaChi2_Phot > 20 & fs > 0.9 & piE < 0.7;
FlagB = DeltaChi2_Phot <= 20 & fs > 0.9;
FlagC = DeltaChi2_Phot > 20 & (fs <= 0.9 | piE >= 0.7); 
FlagD = ~FlagA & ~FlagB & ~FlagC;

cats = struct( ...
    'name',   { "A: $\Delta\chi^2 > 20, f_s > 0.9, \pi_E < 0.7$", ...
                "B: $\Delta\chi^2 \leq 20, f_s > 0.9$", ...
                "C: $\Delta\chi^2 > 20, (f_s \leq 0.9 \vee \pi_{E} \geq 0.7)$", ...
                "D: Rest" }, ...
    'idx',    { find(FlagA), find(FlagB), find(FlagC), find(FlagD) }, ...
    'marker', { '^',  'o',  's',  'd' }, ...
    'color',  { [0.85 0.2 0.2], [0.2 0.6 0.9], [0.2 0.7 0.3], [0.5 0.5 0.5] } ...
);

% Update Legend Strings
legendEntries = strings(1, numel(cats));
for k = 1:numel(cats)
    idx = cats(k).idx;
    nTot = numel(idx);
    nOgle = sum(hasOGLE(idx));
    nKmt  = nTot - nOgle;
    cats(k).name = sprintf("%s\n(N=%d: %d O, %d K)", cats(k).name, nTot, nOgle, nKmt);
    legendEntries(k) = cats(k).name;
end

OutPopDir = fullfile(PlotDirDest, "plots_summary");
if ~exist(OutPopDir, 'dir'), mkdir(OutPopDir); end

% --- PLOT 1: piE vs fs ---
fig = figure('Color','w', 'Position', [100 100 900 700], 'Visible', 'off'); hold on;
hLeg = [];
for c = 1:numel(cats)
    ii = cats(c).idx;
    maskO = hasOGLE(ii); maskK = ~hasOGLE(ii);
    
    h = scatter(piE(ii(maskO)), fs(ii(maskO)), 60, ...
        'Marker', cats(c).marker, 'MarkerFaceColor', cats(c).color, ...
        'MarkerEdgeColor', 'k', 'MarkerFaceAlpha', 0.8);
    hLeg = [hLeg, h];
    
    scatter(piE(ii(maskK)), fs(ii(maskK)), 60, ...
        'Marker', cats(c).marker, 'MarkerFaceColor', 'none', ...
        'MarkerEdgeColor', cats(c).color, 'LineWidth', 1.5, 'HandleVisibility', 'off');
end
xlabel('$\sqrt{\pi_{EN}^2 + \pi_{EE}^2}$','Interpreter','latex', 'FontSize', 14);
ylabel('$f_s$','Interpreter','latex', 'FontSize', 14);
ylim([0.1, 1.4]); grid on;
legend(hLeg, legendEntries, 'Location','best', 'Interpreter', 'latex');

% FIX: Added ContentType vector
exportgraphics(fig, fullfile(OutPopDir, "Pop_piE_vs_fs.eps"), 'ContentType', 'vector');
close(fig);

% --- PLOT 2: DeltaChi2 vs piE ---
fig = figure('Color','w', 'Position', [100 100 900 700], 'Visible', 'off'); hold on;
hLeg = [];
for c = 1:numel(cats)
    ii = cats(c).idx;
    maskO = hasOGLE(ii); maskK = ~hasOGLE(ii);
    
    h = scatter(DeltaChi2_Phot(ii(maskO)), piE(ii(maskO)), 60, ...
        'Marker', cats(c).marker, 'MarkerFaceColor', cats(c).color, ...
        'MarkerEdgeColor', 'k', 'MarkerFaceAlpha', 0.8);
    hLeg = [hLeg, h];
    
    scatter(DeltaChi2_Phot(ii(maskK)), piE(ii(maskK)), 60, ...
        'Marker', cats(c).marker, 'MarkerFaceColor', 'none', ...
        'MarkerEdgeColor', cats(c).color, 'LineWidth', 1.5, 'HandleVisibility', 'off');
end
set(gca,'xscale','log');
xlabel('$\Delta \chi^2$','Interpreter','latex', 'FontSize', 14);
ylabel('$\sqrt{\pi_{EN}^2 + \pi_{EE}^2}$','Interpreter','latex', 'FontSize', 14);
grid on;
legend(hLeg, legendEntries, 'Location','best', 'Interpreter', 'latex');

% FIX: Added ContentType vector
exportgraphics(fig, fullfile(OutPopDir, "Pop_Dchi2_vs_piE.eps"), 'ContentType', 'vector');
close(fig);

% --- PLOT 3: Stacked Histogram ---
fig = figure('Color','w', 'Visible', 'off'); 
fig.Position = [100 100 800 500]; 
hold on;

% 1. Define Bins & Centers
edges = linspace(nanmin(DeltaChi2_Phot), nanmax(DeltaChi2_Phot), 25);
centers = (edges(1:end-1) + edges(2:end)) / 2;

% 2. Calculate Counts
countsMatrix = zeros(length(centers), numel(cats));
for k = 1:numel(cats)
    countsMatrix(:, k) = histcounts(DeltaChi2_Phot(cats(k).idx), edges);
end

% 3. Plot Stacked Bars
b = bar(centers, countsMatrix, 'stacked', 'BarWidth', 1);

% 4. Style
for k = 1:numel(cats)
    b(k).FaceColor = cats(k).color;
    b(k).EdgeColor = 'k'; 
    b(k).LineWidth = 0.5;
    b(k).FaceAlpha = 0.9;
    b(k).DisplayName = legendEntries(k);
end

xlabel('$\Delta \chi^2$','Interpreter','latex', 'FontSize', 14);
ylabel('Count', 'FontSize', 14);

% Fix Limits
xlim([min(edges), max(edges)]);
maxHeight = max(sum(countsMatrix, 2));
if maxHeight > 0
    ylim([0, maxHeight * 1.1]); 
end

legend('Location','northeast', 'Interpreter','latex', 'FontSize', 8);

% Already correct in your snippet, keeping it:
exportgraphics(fig, fullfile(OutPopDir, "Pop_Dchi2_hist_stacked.eps"), 'ContentType', 'vector');
close(fig);

% --- PLOT 4: tE vs piE ---
fig = figure('Color','w', 'Position', [100 100 900 700], 'Visible', 'off'); hold on;
hLeg = [];
for c = 1:numel(cats)
    ii = cats(c).idx;
    maskO = hasOGLE(ii); maskK = ~hasOGLE(ii);
    
    h = scatter(tE(ii(maskO)), piE(ii(maskO)), 60, ...
        'Marker', cats(c).marker, 'MarkerFaceColor', cats(c).color, ...
        'MarkerEdgeColor', 'k', 'MarkerFaceAlpha', 0.8);
    hLeg = [hLeg, h];
    
    scatter(tE(ii(maskK)), piE(ii(maskK)), 60, ...
        'Marker', cats(c).marker, 'MarkerFaceColor', 'none', ...
        'MarkerEdgeColor', cats(c).color, 'LineWidth', 1.5, 'HandleVisibility', 'off');
end
set(gca, 'XScale', 'log', 'YScale', 'log');
xlabel('$t_E$ [days]','Interpreter','latex', 'FontSize', 14);
ylabel('$\sqrt{\pi_{EN}^2 + \pi_{EE}^2}$','Interpreter','latex', 'FontSize', 14);
grid on;
legend(hLeg, legendEntries, 'Location','best', 'Interpreter', 'latex');

% FIX: Added ContentType vector
exportgraphics(fig, fullfile(OutPopDir, "Pop_tE_vs_piE.eps"), 'ContentType', 'vector');
close(fig);

fprintf("Done. Population plots saved to %s\n", OutPopDir);