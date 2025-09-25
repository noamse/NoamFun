function [LogFile,ResFlag]= processKMTEventField(EventNum, opts)
% Process all KMTNet fields for a given EventNum, saving each in its own directory.
% Usage:
%   processKMTEvent(192630, 'Site', 'CTIO', 'FieldToAvoid', 'BLG02');

arguments
    EventNum;
    opts.Site = 'CTIO'
    opts.TargetBasePath = '/home/noamse/KMT/data/Results/'
    opts.FieldToAvoid = ''
    opts.CCDSEC (1,4) double = [106,406,106,406]
    opts.SNPrctileRangeRefCat = [50,95];
    opts.SNRforPSF (1,1) double = 100
    opts.NRefMagBin (1,1) double = 12
    opts.MaxRefMag (1,1) double = 18.5
    opts.MaxRefMagPattern (1,1) double = 16.5
    opts.FitRadius (1,1) double = 3.5
    opts.HalfSize (1,1) double = 12
    opts.InerRadiusKernel (1,1) double = 2.5
    opts.FitRadiusKernel (1,1) double = 5
    opts.Dmin_thresh (1,1) double = 1
    opts.SeczAMThresh (1,1) double = 1.6
    opts.NiterWeightsBeforeSys (1,1) double = 10
    opts.NiterNoWeightsBeforeSys (1,1) double = 2
    opts.NiterWeightsAfterSys (1,1) double = 4
    opts.NIterSysRem (1,1) double = 2
    opts.NWorkers (1,1) double = 32
    opts.ReCalcBack (1,1) logical = false
    opts.FitWings (1,1) logical = true
    opts.RunPhotometry (1,1) logical = true
    opts.RunDetrend (1,1) logical = false
    opts.PathToImagesDirs = '/data1/noamse/KMT/data/images/events_highpriority/';
end

% Define root path
EventNumStr = num2str(EventNum);
RootTargetPath = [fullfile(opts.TargetBasePath, ['kmt', EventNumStr], opts.Site),filesep];
mkdir(RootTargetPath);

% Top-level log file
LogFile = fullfile(RootTargetPath, 'processAllFields.log');
fid = fopen(LogFile, 'w'); fclose(fid);
logmsg(LogFile, '--- Starting event-wide processing session ---');
logmsg(LogFile, sprintf('Event: %s, Site: %s', EventNumStr, opts.Site));
logmsg(LogFile, ['Start time: ', datestr(now, 'yyyy-mm-dd HH:MM:SS')]);

% Build image path based on site
switch upper(opts.Site)
    case 'CTIO'
        Imagebasedir = [opts.PathToImagesDirs, EventNumStr, '/', '*CTIO_I*/'];
    case 'SAAO'
        Imagebasedir = [opts.PathToImagesDirs, EventNumStr, '/', '*SAAO_I*/'];
    otherwise
        Imagebasedir = [opts.PathToImagesDirs, EventNumStr, '/', '*_I*/'];
end

[DirCell, ~] = ml.util.generateDirCell('BaseDir', Imagebasedir, 'Site', opts.Site);
FieldIDs = cellfun(@(fp) regexp(fp, 'BLG\d+', 'match', 'once'), DirCell, 'UniformOutput', false);
UniqueFields = unique(FieldIDs(~cellfun(@isempty, FieldIDs)));
ResFlag = true(numel(UniqueFields),1);
% Handle exclusion
if ~isempty(opts.FieldToAvoid)
    if ischar(opts.FieldToAvoid) || isstring(opts.FieldToAvoid)
        opts.FieldToAvoid = cellstr(opts.FieldToAvoid);
    end
    UniqueFields = setdiff(UniqueFields, opts.FieldToAvoid);
end

logmsg(LogFile, sprintf('Discovered %d unique fields to process.', numel(UniqueFields)));

% === Loop over each BLG field ===
for iField = 1:numel(UniqueFields)
    thisField = UniqueFields{iField};
    logmsg(LogFile, ['--- Processing field: ', thisField, ' ---']);

    DirThisField = DirCell(strcmp(FieldIDs, thisField));
    if isempty(DirThisField)
        logmsg(LogFile, sprintf('No images found for field %s, skipping.', thisField));
        ResFlag(iField)= false;
        continue;
    end

    % Per-field output path
    FieldPath = [fullfile(RootTargetPath, thisField),filesep];
    mkdir(FieldPath);

    LogFileField = fullfile(FieldPath, 'pipeline.log');
    fid = fopen(LogFileField, 'w'); fclose(fid);
    logmsg(LogFileField, sprintf('Processing %d images for %s', numel(DirThisField), thisField));

    % Set pipeline parameters
    Set = ImRed.setParameterStruct(FieldPath, ...
        'CCDSEC_xd', opts.CCDSEC(1), 'CCDSEC_xu', opts.CCDSEC(2), ...
        'CCDSEC_yd', opts.CCDSEC(3), 'CCDSEC_yu', opts.CCDSEC(4), ...
        'MaxRefMag', opts.MaxRefMag, 'FitRadius', opts.FitRadius, ...
        'NRefMagBin', opts.NRefMagBin, 'FitWings', opts.FitWings, ...
        'HalfSize', opts.HalfSize, 'SNRforPSFConstruct', opts.SNRforPSF, ...
        'InerRadiusKernel', opts.InerRadiusKernel, ...
        'FitRadiusKernel', opts.FitRadiusKernel, ...
        'ReCalcBack', opts.ReCalcBack, ...
        'Dmin_thresh', opts.Dmin_thresh, ...
        'MaxRefMagPattern', opts.MaxRefMagPattern, ...
        'fitPSFKernelModel', 'mtd');
    Set.SaveFile = true;

    % === Reference Catalog Generation ===
    try
        [RefCat, Im, ~, ~, LogStr] = ml.generateKMTRefCat(DirThisField, Set, FieldPath, ...
            'Threshold', 50, 'SNPrctileRange', opts.SNPrctileRangeRefCat);
        logmsg(LogFileField, LogStr);
        logmsg(LogFileField, sprintf('Reference catalog contains %d sources.', numel(RefCat.Catalog(:,1))));
        logmsg(LogFileField, 'Reference catalog generated successfully.');
    catch ME
        logmsg(LogFileField, sprintf('Reference catalog generation failed: %s', ME.message));
        ResFlag(iField)=false;
        continue;
    end
    %ds9(Im); XY = [106,106]+RefCat.getCol({'X','Y'});  ds9.plot(XY(RefCat.getCol('I')<16.5,:))
    
    ds9(Im); XY = [106,106]+RefCat.getCol({'X','Y'});  ds9.plot(XY(RefCat.getCol('I')<16.5,:));
    cd('/home/noamse/KMT/data/runPipeBot/')
    ImageFile= ['AlignImage',num2str(EventNum),'Field', thisField];
    epsFile = [ImageFile, '.eps'];
    pngFile = [ImageFile, '.png'];

    ds9.psprint(epsFile);
    cmd = sprintf(['env LD_LIBRARY_PATH= gs -dSAFER -dBATCH -dNOPAUSE -r300 ', ...
        '-sDEVICE=pngalpha -sOutputFile="%s" "%s"'], pngFile, epsFile);
    [status, result] = system(cmd);

    if status == 0
        fprintf('✅ EPS successfully converted: %s\n', pngFile);
        % Load and show the image
        img = imread(pngFile);
        imshow(img);
    else
        error('❌ Conversion failed:\n%s', result);
    end
    ut.sendTelegram(['Trying to match Event',num2str(EventNum),', Field', thisField])
    responseText =ut.sendTelegramImageAndWaitForReply([ImageFile,'.png']);
    if strcmp(responseText,'Bad')
        [RefCat, Im, ~, ~, LogStr] = ml.generateKMTRefCat(DirThisField, Set, FieldPath, ...
            'Threshold', 50, 'SNPrctileRange', opts.SNPrctileRangeRefCat,'CandidateIndices',2:5:100);
        ds9(Im); XY = [106,106]+RefCat.getCol({'X','Y'});  ds9.plot(XY(RefCat.getCol('I')<16.5,:));
        cd('/home/noamse/KMT/data/runPipeBot/')
        ImageFile= ['AlignImage',num2str(EventNum),'Field', thisField];
        epsFile = [ImageFile, '.eps'];
        pngFile = [ImageFile, '.png'];

        ds9.psprint(epsFile);
        cmd = sprintf(['env LD_LIBRARY_PATH= gs -dSAFER -dBATCH -dNOPAUSE -r300 ', ...
            '-sDEVICE=pngalpha -sOutputFile="%s" "%s"'], pngFile, epsFile);
        [status, result] = system(cmd);
        if status == 0
            fprintf('✅ EPS successfully converted: %s\n', pngFile);
            % Load and show the image
            img = imread(pngFile);
            imshow(img);
        else
            error('❌ Conversion failed:\n%s', result);
        end
        responseText =ut.sendTelegramImageAndWaitForReply([ImageFile,'.png']);
        if strcmp(responseText,'Bad')
            ut.sendTelegram(['Failed to match generate Reference catalog: Event',num2str(EventNum),', Field', thisField])
            ResFlag(iField)=false;
            continue;
        end

    end
    %ut.sendTelegram(['Need to inspect new Image for event:',num2str(EventNum),', Field ', thisField])

    if numel(RefCat.Catalog(:,1))<30
        logmsg(LogFileField, 'Reference Catalog has less than 30 sources:stop.');
        ResFlag(iField)=false;
        continue;
    end
    % === Photometry ===
    if opts.RunPhotometry
        if isempty(gcp('nocreate'))
            parpool('local', opts.NWorkers);
        end

        %Set = readtable(fullfile(FieldPath, 'master.txt'));
        MasterPath = fullfile(FieldPath, 'master.txt');

        if ~isfile(MasterPath)
            logmsg(LogFileField, ['[ERROR] master file not found: ', MasterPath]);
            return;
        end

        Set = readtable(MasterPath);
        Set = table2struct(Set);

        parfor Iep = 1:numel(DirThisField)
            success = ImRed.runPipe(DirThisField{Iep}, FieldPath, 'SettingStruct', Set);
            logmsg(LogFileField, sprintf('%s image %d/%d', ...
                ternary(success, '✓', '✗'), Iep, numel(DirThisField)));
        end
    end

    % === Detrending ===
    if opts.RunDetrend
        try
            [Obj, CelestialCoo, Matched] = ml.util.loadAstCatMatch(FieldPath);
            FlagSeczAM = Obj.Data.secz(:,1) < opts.SeczAMThresh;
            Obj.Data = ml.util.flag_struct_field(Obj.Data, FlagSeczAM, 'FlagByCol', false);
            Obj.JD = Obj.JD(FlagSeczAM);
            FlagPix = Obj.Data.Yphase == -0.5 | Obj.Data.Xphase == -0.5;
            Obj.Data.X(FlagPix) = nan; Obj.Data.Y(FlagPix) = nan;

            logmsg(LogFileField, 'Running pre-sysrem detrending...');
            [IFsysB, MMSsysB] = ml.scripts.runIterDetrend(Obj.copy(), ...
                "CelestialCoo", CelestialCoo, 'HALat', true, ...
                'UseWeights', true, 'Plx', false, 'PixPhase', true, ...
                'AnnualEffect', true, ...
                'NiterWeights', opts.NiterWeightsBeforeSys, ...
                'NiterNoWeights', opts.NiterNoWeightsBeforeSys, ...
                'ChromaicHighOrder', true);

            logmsg(LogFileField, 'Running sysrem correction...');
            [ObjSysAfter, ~, ~] = ml.util.sysRemScriptPart(IFsysB, MMSsysB, ...
                'UseWeight', true, 'NIter', opts.NIterSysRem);

            Xguess = median(ObjSysAfter.Data.X, 'omitnan')';
            Yguess = median(ObjSysAfter.Data.Y, 'omitnan')';
            FlagNan = ~(isnan(Xguess) | isnan(Yguess));
            ObjSysAfter.Data = ml.util.flag_struct_field(ObjSysAfter.Data, FlagNan, 'FlagByCol', true);
            Matched.Catalog = Matched.Catalog(FlagNan,:);

            logmsg(LogFileField, 'Running post-sysrem detrending...');
            [~, ~] = ml.scripts.runIterDetrend(ObjSysAfter, 'IF', IFsysB.copy(), ...
                "CelestialCoo", CelestialCoo, 'HALat', true, ...
                'UseWeights', true, 'Plx', false, 'PixPhase', true, ...
                'AnnualEffect', true, ...
                'NiterWeights', opts.NiterWeightsAfterSys, ...
                'NiterNoWeights', opts.NiterNoWeightsBeforeSys, ...
                'ChromaicHighOrder', true, 'FinalStep', true);

            logmsg(LogFileField, 'Detrending completed successfully.');
        catch ME
            logmsg(LogFileField, sprintf('Detrending failed: %s', ME.message));
        end
    end
end  % end loop over fields

end

function logmsg(logFilePath, msg)
    timestamp = datestr(now, 'yyyy-mm-dd HH:MM:SS');
    fid = fopen(logFilePath, 'a');
    if fid ~= -1
        fprintf(fid, '[%s] %s\n', timestamp, msg);
        fclose(fid);
    end
end

function out = ternary(cond, valTrue, valFalse)
    if cond
        out = valTrue;
    else
        out = valFalse;
    end
end
