DirPath = '/home/noamse/KMT/data/Results/AstrometryField/';
TargetPath = '/home/noamse/KMT/data/test/';

SummaryFileMAT = fullfile(TargetPath, 'AstrometryField_Inspect.mat');
SummaryFileCSV = fullfile(TargetPath, 'AstrometryField_Inspect.csv');

Paths = dir(fullfile(DirPath, '*.mat'));

% --- Load existing summary if available ---
if isfile(SummaryFileMAT)
    load(SummaryFileMAT, 'Results');
    fprintf('Loaded existing summary with %d entries.\n', height(Results));
else
    Results = table( ...
        string.empty, zeros(0,1), zeros(0,1), string.empty, ...
        false(0,1), string.empty, zeros(0,1),zeros(0,1), zeros(0,1), zeros(0,1), ...
        'VariableNames', {'FileName','NumID','FieldID','CatsPath','Accepted','Opinion','NSrc','EventInd','RA','Dec'} ...
    );
end

for I = 1:numel(Paths)
    filepath = fullfile(DirPath, Paths(I).name);

    % Extract IDs
    numMatch = regexp(filepath, 'AstrometryField_(\d{6})_', 'tokens', 'once');
    fieldMatch = regexp(filepath, '_BLG(\d{2})\.mat', 'tokens', 'once');

    % Skip if already processed
    if any(Results.FileName == string(Paths(I).name))
        fprintf('Skipping %s (already in summary)\n', Paths(I).name);
        continue;
    end

    % Initialize row info
    FileName = string(Paths(I).name);
    NumID = str2double(numMatch{1});
    FieldID = str2double(fieldMatch{1});
    CatsPath = "";
    Accepted = false;
    Reason = "";
    IndSrc = {};

    % Load the .mat file
    load(filepath);  % should contain variable 'File'

    % --- Check for IFsys field before accessing ---
    if ~exist('File', 'var') || ~isstruct(File) || ~isfield(File, 'IFsys')
        warning('Skipping %s: missing File.IFsys field.', Paths(I).name);
        Reason = "No Astrometry";
        %newRow = {FileName, NumID, FieldID, string(CatsPath), Accepted,  numel(IndSrc)};
        newRow = {FileName, NumID, FieldID, CatsPath, Accepted, "No file", nan,nan,...
        nan,nan};
        Results = [Results; newRow]; %#ok<AGROW>

        % Save and continue
        save(SummaryFileMAT, 'Results');
        writetable(Results, SummaryFileCSV);
        fprintf('⚠️ Logged %s as Bad Astrometry\n', Paths(I).name);
        continue;
    end

    % --- Safe to use File.IFsys now ---
    try
        File.IFsys.plotSource(File.IndForPhotRefernce);
        File.IFsys.plotResRMS;
        screensz = get(0,'ScreenSize');
        for k = 1:numel(screensz)
            figure(k);
            set(gcf, 'Position', [100*k 100*k 500 500]);
        end
    catch ME
        warning('Plotting error in %s: %s', Paths(I).name, ME.message);
    end

    % Ask user for decision
    fprintf('Incpecing %s :\n', Paths(I).name);
% Ask user for decision (forces valid yes/no)
while true
    userInput = lower(strtrim(input('Process this file? (yes/no): ', 's')));
    if any(strcmp(userInput, {'yes','y'}))
        userInput = 'yes';
        break;  % exit loop only if input is valid
    elseif any(strcmp(userInput, {'no','n'}))
        userInput = 'no';
        break;
    else
        fprintf('❌ Invalid input. Please type "yes" or "no".\n');
    end
end

if strcmp(userInput, 'yes')
    CatsPath = fullfile(TargetPath, ['kmt', numMatch{1}, '_', fieldMatch{1}], filesep);
    %[CatsPath, IndSrc] = ml.scripts.IterFitToPerSourceFormat(File.IFsys, CatsPath, 'MaxMag', 17.5);
    %[CatsPath, IndSrc] = ml.scripts.IterFitToPerSourceFormat(File.IFsys, CatsPath, 'MaxMag', 17.5);
    IndSrc = File.IndForPhotRefernce;
    Accepted = true;
elseif strcmp(userInput, 'no')
    Accepted = false;
    %Reason = input('Why not? ', 's');
end
    Opinion = input('What do you think? ', 's');
    % Add row to table
    newRow = {FileName, NumID, FieldID, string(CatsPath), Accepted,string(Opinion), numel(IndSrc),File.IndForPhotRefernce,...
        File.FieldCenterDeg(1),File.FieldCenterDeg(2)};
    Results = [Results; newRow]; %#ok<AGROW>

    % --- Save after each iteration ---
    save(SummaryFileMAT, 'Results');
    writetable(Results, SummaryFileCSV);
    fprintf('✅ Updated summary after %s\n', Paths(I).name);

    clear File
end

fprintf('\n🎯 All files processed. Final summary saved to:\n%s\n%s\n', ...
    SummaryFileMAT, SummaryFileCSV);


%%
load('/home/noamse/KMT/data/test/AstrometryField_Summary.mat', 'Results');

% Filter accepted rows
AcceptedRows = Results(Results.Accepted == true, :);

% Open text file for writing
txtFile = fullfile('/home/noamse/KMT/data/test/', 'AcceptedFieldsAll.txt');
fid = fopen(txtFile, 'w');

% Write each accepted field in the format "###### %%"
for i = 1:height(AcceptedRows)
    fprintf(fid, '%06d %02d\n', AcceptedRows.NumID(i), AcceptedRows.FieldID(i));
end

fclose(fid);

fprintf('✅ Created text file with %d accepted fields:\n%s\n', height(AcceptedRows), txtFile);



%%
% code for inspection over events and results
DirPlots = '/home/noamse/KMT/data/EVENTS/plots/';
DirAst1 = '/home/noamse/KMT/data/Results/AstrometryField/';
DirAst2 = '/home/noamse/KMT/data/Results/AstrometryField/high_priority/';


% Each event has 3 plot files. For example:
% results_kmt170172_42_0_0_corr_multi.png,
% results_kmt170172_42_0_0_chi2_multi.png
% results_kmt170172_42_0_0_chi2_diff_multi.png
% and one astrometryFiled file, for example in DirAst2:
% /home/noamse/KMT/data/Results/AstrometryField/high_priority/AstrometryField_170172_CTIO_BLG42.mat

% I need to write a for loop that need to go over events that appears in DirPlots, plot all 3
% files, and load the relevant astrometryField file. The code need to check
% wether the file in DirAst1 or DirAst2

%%
% Directories
DirPlots = '/home/noamse/KMT/data/EVENTS/plots/';
DirAst1  = '/home/noamse/KMT/data/Results/AstrometryField/';
DirAst2  = '/home/noamse/KMT/data/Results/AstrometryField/high_priority/';
InspectionDBPath = '/home/noamse/KMT/data/Results/';
% Database file
dbFileMAT = fullfile(InspectionDBPath, 'inspectionDB.mat');
dbFileCSV = fullfile(InspectionDBPath, 'inspectionDB.csv');

% Initialize database if missing
if exist(dbFileMAT, 'file')
    load(dbFileMAT, 'inspectionDB');
else
    inspectionDB = struct('eventID', {}, 'fieldID', {}, 'pathAst', {}, ...
                          'classification', {}, 'comment', {}, 'timestamp', {});
end

% Get all PNG plots (use chi2_multi to define unique events)
allPlots = dir(fullfile(DirPlots, 'results_kmt*_chi2_multi.png'));

for k = 1:numel(allPlots)
    close all;
    name = allPlots(k).name;
    tokens = regexp(name, 'results_kmt(\d+)_([0-9]+)_0_0_', 'tokens', 'once');
    if isempty(tokens)
        continue
    end
    eventID = tokens{1};
    fieldID = tokens{2};

    % Skip if already logged
    alreadyDone = any(arrayfun(@(x) strcmp(x.eventID, eventID) && strcmp(x.fieldID, fieldID), inspectionDB));
    if alreadyDone
        fprintf('Skipping event %s field %s (already inspected)\n', eventID, fieldID);
        continue
    end

    % --- Plot section ---
    plotCorr = fullfile(DirPlots, sprintf('results_kmt%s_%s_0_0_corr_multi.png', eventID, fieldID));
    plotChi2 = fullfile(DirPlots, sprintf('results_kmt%s_%s_0_0_chi2_multi.png', eventID, fieldID));
    plotChi2Diff = fullfile(DirPlots, sprintf('results_kmt%s_%s_0_0_chi2_diff_multi.png', eventID, fieldID));

    figure('Name', sprintf('Event %s Field %s', eventID, fieldID), 'NumberTitle', 'off');
    t = tiledlayout(1,3, 'Padding','compact');
    titles = {'chi2 diff', 'chi2', 'corr'};
    plotFiles = {plotChi2Diff, plotChi2, plotCorr};
    for i = 1:3
        nexttile;
        if exist(plotFiles{i}, 'file')
            imshow(imread(plotFiles{i}));
            title(titles{i}, 'Interpreter','none');
        else
            title(['Missing: ' titles{i}]);
        end
    end

    % --- Astrometry file ---
    astFileName = sprintf('AstrometryField_%s_CTIO_BLG%s.mat', eventID, fieldID);
    astPath1 = fullfile(DirAst1, astFileName);
    astPath2 = fullfile(DirAst2, astFileName);

    if exist(astPath1, 'file')
        astPath = astPath1;
    elseif exist(astPath2, 'file')
        astPath = astPath2;
    else
        warning('AstrometryField file not found for event %s field %s', eventID, fieldID);
        astPath = '';
    end
    if ~isempty(astPath)
        load(astPath);
        figure;
        File.IFsys.plotSource(File.IndForPhotRefernce,'CloseAll',false);
        File.IFsys.plotResRMS;
        
    end
    % --- User input ---
    fprintf('\nInspecting event %s (field %s)\n', eventID, fieldID);
    classification = input('Classification (e.g. binary, variable, noise): ', 's');
    comment = input('Comment (optional): ', 's');

    % --- Record entry ---
    newEntry = struct('eventID', eventID, ...
                      'fieldID', fieldID, ...
                      'pathAst', astPath, ...
                      'classification', classification, ...
                      'comment', comment, ...
                      'timestamp', datestr(now, 'yyyy-mm-dd HH:MM:SS'));

    inspectionDB(end+1) = newEntry; %#ok<SAGROW>

    % --- Save both .mat and .csv for convenience ---
    save(dbFileMAT, 'inspectionDB');

    try
        T = struct2table(inspectionDB, 'AsArray', true);
        writetable(T, dbFileCSV);
    catch ME
        warning('Could not write CSV: %s', ME.message);
    end

    fprintf('Saved inspection for event %s field %s\n\n', eventID, fieldID);
end

fprintf('All inspections completed.\n');







%%
DirPath = '/home/noamse/KMT/data/Results/AstrometryField/';
%CatsTarget = '/home/noamse/KMT/data/CatsKMT/';
CatsTarget = '/data4/KMT/data/CatsKMT/';
Tins = readtable(fullfile(TargetPath, 'AstrometryField_Inspect.csv'));
Tins  = Tins(logical(Tins.Accepted),:);
for Ind = 1:numel(Tins(:,1))
    filepath = fullfile(DirPath,Tins.FileName{Ind});
    load(filepath);
    numMatch = regexp(Tins.FileName{Ind}, 'AstrometryField_(\d{6})_', 'tokens', 'once');
    fieldMatch = regexp(Tins.FileName{Ind}, '_BLG(\d{2})\.mat', 'tokens', 'once');
    CatsPath = fullfile(CatsTarget, ['kmt', numMatch{1}, '_', fieldMatch{1}], filesep);
    % Now using the new outlier detection method ml.util.detectOutliers_DualStage
    [CatsPath, IndSrc] = ml.scripts.IterFitToPerSourceFormat(File.IFsys, CatsPath, 'MaxMag', 17.5);
    disp(['Finish to extract - ' 'kmt', numMatch{1}, '_', fieldMatch{1}, '. Nsrc = ' num2str(numel(IndSrc))])


end





%%
DirPath = '/home/noamse/KMT/data/Results/AstrometryField/';
CatsTarget = '/home/noamse/KMT/data/CatsKMT/';
Tins = readtable(fullfile(TargetPath, 'AstrometryField_Inspect.csv'));
Tins  = Tins(logical(Tins.Accepted),:);

for Ind = 1:numel(Tins(:,1))
    [lcTbl,meta] = ml.kmt.readKMTNetLightCurve(Tins.NumID(Ind),Tins.FieldID(Ind));
    sprintf('Downloaded for %d , %d ', Tins.NumID(Ind),Tins.FieldID(Ind))
end