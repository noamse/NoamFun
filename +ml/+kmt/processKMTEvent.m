function LogFile = processKMTEvent(EventNum, opts)
% Process a KMTNet field for a given EventNum with flexible options and logging.
% Example usage:
%   processKMTEvent(192630, 'Site', 'CTIO', 'NWorkers', 8)

arguments
    EventNum;
    opts.Site = 'CTIO'
    opts.TargetBasePath  = '/home/noamse/KMT/data/Results/'
    opts.FieldToAvoid = '';
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
    opts.NWorkers (1,1) double = 16
    opts.ReCalcBack (1,1) logical = false
    opts.FitWings (1,1) logical = true
    opts.RunPhotometry (1,1) logical = true
    opts.RunDetrend (1,1) logical = false
    opts.PathToImagesDirs = '/data1/noamse/KMT/data/images/events_highpriority/';
end

EventNumStr = num2str(EventNum);
TargetPath = fullfile(opts.TargetBasePath, ['kmt', EventNumStr], opts.Site,filesep);
mkdir(TargetPath);

LogFile = fullfile(TargetPath, 'pipeline.log');
fid = fopen(LogFile, 'w');  
fclose(fid);
logmsg(LogFile, '--- Starting new log session ---');
logmsg(LogFile, sprintf('Processing event %s at site %s', EventNumStr, opts.Site));
logmsg(LogFile, ['Start time: ', datestr(now, 'yyyy-mm-dd HH:MM:SS')]);
logmsg(LogFile, TargetPath);

% Set up image directory
switch upper(opts.Site)
    case 'CTIO'
        Imagebasedir = [opts.PathToImagesDirs, EventNumStr, '/', '*CTIO_I*/'];
    case 'SAAO'
        Imagebasedir = [opts.PathToImagesDirs, EventNumStr, '/', '*SAAO_I*/'];
    otherwise
        Imagebasedir = [opts.PathToImagesDirs, EventNumStr, '/', '*_I*/'];
end

[DirCell, ~] = ml.util.generateDirCell('BaseDir', Imagebasedir, 'Site', opts.Site);
%DirCell = DirCell(~contains(DirCell, 'REF'));
FieldIDs = cellfun(@(fp) regexp(fp, 'BLG\d+', 'match', 'once'), ...
                   DirCell, 'UniformOutput', false);

if ~isempty(opts.FieldToAvoid)
    DirCell = DirCell(~contains(DirCell, opts.FieldToAvoid));
end

logmsg(LogFile, sprintf('Found %d usable image directories', numel(DirCell)));

% Set up pipeline parameters
Set = ImRed.setParameterStruct(TargetPath, ...
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

% Generate reference catalog
try
    [RefCat, Im, ~, ~,LogStr] = ml.generateKMTRefCat(DirCell, Set, TargetPath, ...
        'Threshold', 100,'SNPrctileRange',opts.SNPrctileRangeRefCat);
    logmsg(LogFile,LogStr);
    logmsg(LogFile, sprintf('Reference catalog contains %d sources.', numel(RefCat.Catalog(:,1))));
    %logmsg(LogFile, sprintf('Median I: %.2f', median(RefCat.getCol('I'), 'omitnan')));
    logmsg(LogFile, 'Reference catalog generated successfully.');
catch ME
    logmsg(LogFile, sprintf('Reference catalog generation failed: %s', ME.message));
    return;
end

% Run photometry
if opts.RunPhotometry
    if isempty(gcp('nocreate'))
        parpool('local', opts.NWorkers);
    end
    
    %ReadOpts  = detectImportOptions([TargetPath,'master.txt']);
    Set = readtable([TargetPath,'master.txt']);
    Set = table2struct(Set);

    %detectImportOptions()
    parfor Iep = 1:numel(DirCell)
        success = ImRed.runPipe(DirCell{Iep},TargetPath,'SettingStruct',Set);
        if success
            logmsg(LogFile, sprintf('Successfully processed image %d of %d', Iep, numel(DirCell)));
        else
            logmsg(LogFile, sprintf('FAILED to process image %d of %d', Iep, numel(DirCell)));
        end
    end
end
% Run detrending
if opts.RunDetrend
    try
        [Obj, CelestialCoo, Matched] = ml.util.loadAstCatMatch(TargetPath);
        FlagSeczAM = Obj.Data.secz(:,1) < opts.SeczAMThresh;
        Obj.Data = ml.util.flag_struct_field(Obj.Data, FlagSeczAM, 'FlagByCol', false);
        Obj.JD = Obj.JD(FlagSeczAM);
        FlagPix = Obj.Data.Yphase==-0.5 | Obj.Data.Xphase==-0.5;
        Obj.Data.X(FlagPix) = nan; Obj.Data.Y(FlagPix) = nan;

        logmsg(LogFile, sprintf('Running pre-sysrem detrending: W=%d, NW=%d', ...
            opts.NiterWeightsBeforeSys, opts.NiterNoWeightsBeforeSys));
        [IFsysB, MMSsysB] = ml.scripts.runIterDetrend(Obj.copy(), ...
            "CelestialCoo", CelestialCoo, 'HALat', true, ...
            'UseWeights', true, 'Plx', false, 'PixPhase', true, ...
            'AnnualEffect', true, ...
            'NiterWeights', opts.NiterWeightsBeforeSys, ...
            'NiterNoWeights', opts.NiterNoWeightsBeforeSys, ...
            'ChromaicHighOrder', true);

        logmsg(LogFile, sprintf('Running sysrem correction: NIter=%d', opts.NIterSysRem));
        [ObjSysAfter, ~, ~] = ml.util.sysRemScriptPart(IFsysB, MMSsysB, ...
            'UseWeight', true, 'NIter', opts.NIterSysRem);

        Xguess = median(ObjSysAfter.Data.X, 'omitnan')';
        Yguess = median(ObjSysAfter.Data.Y, 'omitnan')';
        FlagNan = ~(isnan(Xguess) | isnan(Yguess));
        ObjSysAfter.Data = ml.util.flag_struct_field(ObjSysAfter.Data, FlagNan, 'FlagByCol', true);
        Matched.Catalog = Matched.Catalog(FlagNan,:);

        logmsg(LogFile, sprintf('Running post-sysrem detrending: W=%d, NW=%d', ...
            opts.NiterWeightsAfterSys, opts.NiterNoWeightsBeforeSys));
        [~, ~] = ml.scripts.runIterDetrend(ObjSysAfter, 'IF', IFsysB.copy(), ...
            "CelestialCoo", CelestialCoo, 'HALat', true, ...
            'UseWeights', true, 'Plx', false, 'PixPhase', true, ...
            'AnnualEffect', true, ...
            'NiterWeights', opts.NiterWeightsAfterSys, ...
            'NiterNoWeights', opts.NiterNoWeightsBeforeSys, ...
            'ChromaicHighOrder', true, 'FinalStep', true);

        logmsg(LogFile, 'Detrending completed successfully.');
    catch ME
        logmsg(LogFile, sprintf('Detrending failed: %s', ME.message));
    end
end
end

function logmsg(logFilePath, msg)
    timestamp = datestr(now, 'yyyy-mm-dd HH:MM:SS');
    fid = fopen(logFilePath, 'a');
    if fid == -1
        warning('Could not open log file: %s', logFilePath);
        return;
    end
    fprintf(fid, '[%s] %s\n', timestamp, msg);
    fclose(fid);
end