%% Histogram all params from hierarchical JSONs, Opinion==A only

clear; clc;

% --- settings ---
csvPath  = '/home/noamse/KMT/data/test/AstrometryField_Inspect_A.csv';

% NEW hierarchy root:
jsonRoot = '/home/noamse/KMT/data/Experiments/Comb_A_v1/photometry_outputs';
% (change to Comb_blend_all/photometry_outputs if needed)

variantPattern = "params_photo-aux_*std*.json";  % choose std here
% variantPattern = "params_photo-aux_*best*.json"; % or best

magCut   = 0;   % set [] to disable split by mag0

% ---------- read CSV ----------
T = readtable(csvPath);
T_A = T(strcmp(T.Opinion, 'A'), :);
fprintf('CSV rows with Opinion==A: %d\n', height(T_A));

% ---------- extract event names from CatsPath ----------
cats = T_A.CatsPath;
cats = cats(~cellfun(@isempty, cats));

eventNames = strings(size(cats));
IndTa = nan(size(cats));

for i = 1:numel(cats)
    p = strip(cats{i});
    p = regexprep(p, '/+$', '');
    parts = strsplit(p, '/');
    eventNames(i) = string(parts{end});
    IndTa(i) = T_A.EventInd(i);
end

eventNames = unique(eventNames);
fprintf('Unique A-events found: %d\n', numel(eventNames));
disp(eventNames);

% ---------- find event directories under jsonRoot ----------
evDirsAll = dir(fullfile(jsonRoot, "kmt*"));
evDirsAll = evDirsAll([evDirsAll.isdir]);

% keep only directories that are in eventNames (Opinion==A)
isA = ismember(string({evDirsAll.name}), eventNames);
evDirsA = evDirsAll(isA);

fprintf("Event dirs matching Opinion==A: %d\n", numel(evDirsA));
if isempty(evDirsA)
    error("No matching event directories under %s", jsonRoot);
end

% ---------- collect JSON objects ----------
objs = {};   % cell of structs
evKeep = strings(0);

for i = 1:numel(evDirsA)
    ev = string(evDirsA(i).name);
    evDir = fullfile(evDirsA(i).folder, evDirsA(i).name);

    jfiles = dir(fullfile(evDir, variantPattern));
    if isempty(jfiles)
        fprintf("⚠️  No JSON matching %s in %s\n", variantPattern, evDir);
        continue;
    end

    % pick first match (or newest if multiple)
    jf = fullfile(jfiles(1).folder, jfiles(1).name);

    try
        obj = jsondecode(fileread(jf));
        objs{end+1} = obj; %#ok<SAGROW>
        evKeep(end+1) = ev; %#ok<SAGROW>
    catch ME
        warning("Failed reading %s: %s", jf, ME.message);
    end
end

if isempty(objs)
    error("No usable JSONs collected.");
end

% ---------- build numeric parameter matrix ----------
paramNames = fieldnames(objs{1});

n = numel(objs);
params = struct();
for k = 1:numel(paramNames)
    params.(paramNames{k}) = nan(n,1);
end

for i = 1:n
    obj = objs{i};
    for k = 1:numel(paramNames)
        name = paramNames{k};
        if isfield(obj, name)
            val = obj.(name);
            if isnumeric(val) && isscalar(val)
                params.(name)(i) = val;
            end
        end
    end
end

% keep only numeric parameters with any finite values
keepParam = false(size(paramNames));
for k = 1:numel(paramNames)
    keepParam(k) = any(~isnan(params.(paramNames{k})));
end
paramNames = paramNames(keepParam);

X = nan(n, numel(paramNames));
for k = 1:numel(paramNames)
    X(:,k) = params.(paramNames{k});
end

goodRows = all(~isnan(X),2);
X = X(goodRows,:);
fprintf('Final usable events: %d\n', size(X,1));

% ---------- plotting ----------
if isempty(magCut)
    plot_histograms(X, paramNames);
    corner_plot(X, paramNames, sprintf('Corner plot Opinion==A (N=%d)', size(X,1)));
else
    mag0_idx = find(strcmp(paramNames,'mag0'),1);
    if isempty(mag0_idx)
        error('mag0 not present in params; cannot split by mag.');
    end

    mag0 = X(:,mag0_idx);
    isBright = mag0 < magCut;
    isFaint  = mag0 >= magCut;

    plot_split_histograms(X, paramNames, isBright, isFaint, magCut);

    if any(isBright)
        corner_plot(X(isBright,:), paramNames, ...
            sprintf('Corner Opinion==A | mag0<%.1f (N=%d)', magCut, sum(isBright)));
    end
    if any(isFaint)
        corner_plot(X(isFaint,:), paramNames, ...
            sprintf('Corner Opinion==A | mag0>=%.1f (N=%d)', magCut, sum(isFaint)));
    end
end


% ===== helper plots =====
function plot_histograms(X, labels)
    nParams = numel(labels);
    nCols = 3; nRows = ceil(nParams/nCols);
    figure('Color','w','Name','Histograms Opinion==A');
    tiledlayout(nRows,nCols,'Padding','compact','TileSpacing','compact');

    for k = 1:nParams
        nexttile;
        histogram(X(:,k), 'BinMethod','fd');
        xlabel(labels{k},'Interpreter','none');
        ylabel('Count'); grid on;
        title(labels{k},'Interpreter','none');
    end
end

function plot_split_histograms(X, labels, isBright, isFaint, magCut)
    nParams = numel(labels);
    nCols = 3; nRows = ceil(nParams/nCols);
    figure('Color','w','Name','Split histograms Opinion==A');
    tiledlayout(nRows,nCols,'Padding','compact','TileSpacing','compact');

    for k = 1:nParams
        dataBright = X(isBright,k);
        dataFaint  = X(isFaint,k);
        nexttile; hold on;
        if ~isempty(dataBright)
            histogram(dataBright,'BinMethod','fd','DisplayStyle','stairs','LineWidth',1.5);
        end
        if ~isempty(dataFaint)
            histogram(dataFaint,'BinMethod','fd','DisplayStyle','stairs','LineWidth',1.5);
        end
        hold off; grid on;
        xlabel(labels{k},'Interpreter','none'); ylabel('Count');
        title(labels{k},'Interpreter','none');
        legend({sprintf('mag0<%.1f (N=%d)',magCut,numel(dataBright)), ...
                sprintf('mag0>=%.1f (N=%d)',magCut,numel(dataFaint))}, ...
                'Location','best','Box','off');
    end
end

function corner_plot(X, labels, figTitle)
    [~,D] = size(X);
    figure('Color','w','Name',figTitle);
    tiledlayout(D,D,'Padding','compact','TileSpacing','compact');

    for i = 1:D
        for j = 1:D
            nexttile;
            if i==j
                histogram(X(:,i),'BinMethod','fd');
            elseif i>j
                scatter(X(:,j),X(:,i),8,'filled'); grid on;
            else
                axis off; continue;
            end

            if i==D, xlabel(labels{j},'Interpreter','none');
            else, set(gca,'XTickLabel',[]); end

            if j==1 && i>1, ylabel(labels{i},'Interpreter','none');
            else, if i~=j, set(gca,'YTickLabel',[]); end, end
        end
    end
    sgtitle(figTitle,'Interpreter','none');
end



%{
%% Histogram all params from *_best.json, split by mag0 < 17

% --- settings ---
%dataDir = '/home/noamse/KMT/data/Experiments/Photometry_v2/all_params_photo_aux_variants';  % or set explicitly






%csvPath  = '/home/noamse/KMT/data/test/AstrometryField_Inspect.csv';  % <- set your CSV
csvPath  = '/home/noamse/KMT/data/test/AstrometryField_Inspect_A.csv';
%jsonDir  = '/home/noamse/KMT/data/Experiments/Photometry_v2/all_params_photo_aux_variants';  % directory containing kmtXXXX_YY__params_photo-aux_WIS-1_best.json
jsonDir ='~/KMT/data/Experiments/Comb_A_v1/all_params_photo_aux_variants';
magCut   = 0;   % if you still want mag0 split; set [] to disable

% ---------- read CSV ----------
T = readtable(csvPath);

% Opinion is a cellstr column in your CSV, so compare with strcmp
T_A = T(strcmp(T.Opinion, 'A'), :);

fprintf('CSV rows with Opinion==A: %d\n', height(T_A));

% ---------- extract event names from CatsPath ----------
% CatsPath has full paths like /home/noamse/KMT/data/CatsKMT/kmt160009_02/
cats = T_A.CatsPath;

% remove empties just in case
cats = cats(~cellfun(@isempty, cats));

% take last folder name
eventNames = cell(size(cats));
for i = 1:numel(cats)
    p = strip(cats{i});
    p = regexprep(p, '/+$', '');          % remove trailing /
    parts = strsplit(p, '/');
    eventNames{i} = parts{end};           % e.g. kmt160023_42
end

eventNames = unique(eventNames);
fprintf('Unique A-events found: %d\n', numel(eventNames));
disp(eventNames);

% ---------- find best json files ----------
files = dir(fullfile(jsonDir, '*_std.json'));
if isempty(files)
    error('No *_best.json files found in %s', jsonDir);
end

% Keep only those whose filename starts with one of the A event names
keepFile = false(numel(files),1);
for i = 1:numel(files)
    fname = files(i).name;  % e.g. kmt160023_42__params_photo-aux_WIS-1_best.json
    for j = 1:numel(eventNames)
        prefix = [eventNames{j} '__'];
        if startsWith(fname, prefix)
            keepFile(i) = true;
            break;
        end
    end
end

filesA = files(keepFile);
fprintf('Best JSON files matching Opinion==A: %d\n', numel(filesA));

if isempty(filesA)
    error('No matching *_best.json files for Opinion==A.');
end

% ---------- read jsons and collect params ----------
firstObj   = jsondecode(fileread(fullfile(jsonDir, filesA(1).name)));
paramNames = fieldnames(firstObj);

nFilesA = numel(filesA);
params = struct();
for k = 1:numel(paramNames)
    params.(paramNames{k}) = nan(nFilesA, 1);
end

for i = 1:nFilesA
    obj = jsondecode(fileread(fullfile(jsonDir, filesA(i).name)));
    for k = 1:numel(paramNames)
        name = paramNames{k};
        if isfield(obj, name)
            val = obj.(name);
            if isnumeric(val) && isscalar(val)
                params.(name)(i) = val;
            end
        end
    end
end

% keep only numeric parameters
keepParam = false(size(paramNames));
for k = 1:numel(paramNames)
    keepParam(k) = any(~isnan(params.(paramNames{k})));
end
paramNames = paramNames(keepParam);

% Build matrix X
X = nan(nFilesA, numel(paramNames));
for k = 1:numel(paramNames)
    X(:,k) = params.(paramNames{k});
end

% Drop rows missing any selected param
goodRows = all(~isnan(X),2);
X = X(goodRows,:);
fprintf('Final usable events: %d\n', size(X,1));

% ---------- plotting ----------
if isempty(magCut)
    % simple histograms
    plot_histograms(X, paramNames);
    corner_plot(X, paramNames, sprintf('Corner plot Opinion==A (N=%d)', size(X,1)));
else
    % mag split hist + 2 corner plots
    mag0_idx = find(strcmp(paramNames,'mag0'),1);
    if isempty(mag0_idx)
        error('mag0 not present in params; cannot split by mag.');
    end

    mag0 = X(:,mag0_idx);
    isBright = mag0 < magCut;
    isFaint  = mag0 >= magCut;

    plot_split_histograms(X, paramNames, isBright, isFaint, magCut);

    if any(isBright)
        corner_plot(X(isBright,:), paramNames, ...
            sprintf('Corner Opinion==A | mag0<%.1f (N=%d)', magCut, sum(isBright)));
    end
    if any(isFaint)
        corner_plot(X(isFaint,:), paramNames, ...
            sprintf('Corner Opinion==A | mag0>=%.1f (N=%d)', magCut, sum(isFaint)));
    end
end


% ===== helper plots =====
function plot_histograms(X, labels)
    nParams = numel(labels);
    nCols = 3; nRows = ceil(nParams/nCols);
    figure('Color','w','Name','Histograms Opinion==A');
    tiledlayout(nRows,nCols,'Padding','compact','TileSpacing','compact');

    for k = 1:nParams
        nexttile;
        histogram(X(:,k), 'BinMethod','fd');
        xlabel(labels{k},'Interpreter','none');
        ylabel('Count'); grid on;
        title(labels{k},'Interpreter','none');
    end
end

function plot_split_histograms(X, labels, isBright, isFaint, magCut)
    nParams = numel(labels);
    nCols = 3; nRows = ceil(nParams/nCols);
    figure('Color','w','Name','Split histograms Opinion==A');
    tiledlayout(nRows,nCols,'Padding','compact','TileSpacing','compact');

    for k = 1:nParams
        dataBright = X(isBright,k);
        dataFaint  = X(isFaint,k);
        nexttile; hold on;
        if ~isempty(dataBright)
            histogram(dataBright,'BinMethod','fd','DisplayStyle','stairs','LineWidth',1.5);
        end
        if ~isempty(dataFaint)
            histogram(dataFaint,'BinMethod','fd','DisplayStyle','stairs','LineWidth',1.5);
        end
        hold off; grid on;
        xlabel(labels{k},'Interpreter','none'); ylabel('Count');
        title(labels{k},'Interpreter','none');
        legend({sprintf('mag0<%.1f (N=%d)',magCut,numel(dataBright)), ...
                sprintf('mag0>=%.1f (N=%d)',magCut,numel(dataFaint))}, ...
                'Location','best','Box','off');
    end
end

function corner_plot(X, labels, figTitle)
    [~,D] = size(X);
    figure('Color','w','Name',figTitle);
    tiledlayout(D,D,'Padding','compact','TileSpacing','compact');

    for i = 1:D
        for j = 1:D
            nexttile;
            if i==j
                histogram(X(:,i),'BinMethod','fd');
            elseif i>j
                scatter(X(:,j),X(:,i),8,'filled'); grid on;
            else
                axis off; continue;
            end

            if i==D, xlabel(labels{j},'Interpreter','none');
            else, set(gca,'XTickLabel',[]); end

            if j==1 && i>1, ylabel(labels{i},'Interpreter','none');
            else, if i~=j, set(gca,'YTickLabel',[]); end, end
        end
    end
    sgtitle(figTitle,'Interpreter','none');
end





%%

%% Compare chi2 between *_best.json and *_std.json per event

%dataDir = '/home/noamse/KMT/data/Experiments/Photometry_v2/all_params_photo_aux_variants/';  % or set your directory explicitly
dataDir = jsonDir;
bestFiles = dir(fullfile(dataDir, '*_best.json'));
stdFiles  = dir(fullfile(dataDir, '*_std.json'));

if isempty(bestFiles)
    error('No *_best.json files found in %s', dataDir);
end
if isempty(stdFiles)
    error('No *_std.json files found in %s', dataDir);
end

% --- Helper to extract event name (prefix before "__") ---
getEvent = @(fname) regexp(fname, '^(.*?)__', 'tokens', 'once');

% Build maps event -> filename
bestMap = containers.Map('KeyType','char','ValueType','char');
stdMap  = containers.Map('KeyType','char','ValueType','char');

for i = 1:numel(bestFiles)
    ev = getEvent(bestFiles(i).name);
    if ~isempty(ev)
        bestMap(ev{1}) = bestFiles(i).name;
    end
end

for i = 1:numel(stdFiles)
    ev = getEvent(stdFiles(i).name);
    if ~isempty(ev)
        stdMap(ev{1}) = stdFiles(i).name;
    end
end

% Events that have BOTH best and std
eventsBest = keys(bestMap);
eventsStd  = keys(stdMap);
eventsBoth = intersect(eventsBest, eventsStd);

fprintf('Found %d paired events (best+std)\n', numel(eventsBoth));

% Preallocate results
n = numel(eventsBoth);
eventName = strings(n,1);
chi2_best = nan(n,1);
chi2_std  = nan(n,1);

for k = 1:n
    ev = eventsBoth{k};
    eventName(k) = ev;

    % read best chi2
    fBest = fullfile(dataDir, bestMap(ev));
    objBest = jsondecode(fileread(fBest));
    if isfield(objBest, 'chi2')
        chi2_best(k) = objBest.chi2;
    end

    % read std chi2
    fStd = fullfile(dataDir, stdMap(ev));
    objStd = jsondecode(fileread(fStd));
    if isfield(objStd, 'chi2')
        chi2_std(k) = objStd.chi2;
    end
end

% Build comparison metrics
dchi2   = chi2_best - chi2_std;
ratio   = chi2_best ./ chi2_std;

% Put in a table
Tcmp = table(eventName, chi2_best, chi2_std, dchi2, ratio);
Tcmp = sortrows(Tcmp, 'dchi2');   % sort by improvement

disp(Tcmp);

% Save to CSV for later
writetable(Tcmp, fullfile(dataDir, 'chi2_best_vs_std.csv'));
fprintf('Wrote chi2_best_vs_std.csv\n');

% ---- Plot 1: chi2_best vs chi2_std scatter ----
figure('Color','w','Name','chi2 best vs std');
scatter(chi2_std, chi2_best, 20, 'filled');
grid on; axis tight;

xlabel('\chi^2_{std}');
ylabel('\chi^2_{best}');
title(sprintf('\\chi^2 comparison (N=%d)', n));

% 1:1 line
hold on;
mn = min([chi2_std; chi2_best]);
mx = max([chi2_std; chi2_best]);
plot([mn mx],[mn mx],'k--','LineWidth',1);
hold off;

% ---- Plot 2: histogram of delta chi2 ----
figure('Color','w','Name','Delta chi2');
histogram(dchi2, 'BinMethod','fd');
grid on;

xlabel('\Delta\chi^2 = \chi^2_{best} - \chi^2_{std}');
ylabel('Count');
title('Distribution of \Delta\chi^2');

% Print quick summary
fprintf('Median Δchi2: %.3f\n', median(dchi2,'omitnan'));
fprintf('Fraction improved (Δchi2 < 0): %.3f\n', mean(dchi2 < 0,'omitnan'));
%}