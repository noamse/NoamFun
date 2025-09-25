function OutputFileName = runAstrometryField(EventNum, Args)
arguments
    EventNum

    % --- runOverFields arguments ---
    Args.RunReduction = false
    Args.processKMTEventsArgs = {}
    Args.TargetBasePath = '/home/noamse/KMT/data/Results/'
    Args.TargetPath = ''
    Args.PerSourcesTargetPath = '/home/noamse/KMT/data/EVENTS/'
    Args.Site = 'CTIO'
    Args.Field = '';
    % --- gaiaAstrometryKMT arguments ---
    Args.GaiaCatMatchedFile = []
    Args.RstdTopPrc = 33
    Args.MaxMag = 18

    % --- global flags ---
    Args.Save = true;
    Args.OutputDir = '/home/noamse/KMT/data/Results/AstrometryField/'
end

% Step 1: Run over fields with selected arguments
[CatsPath, IFsys, Obj, Matched] = ml.scripts.runOverFields(EventNum, ...
    'RunReduction', Args.RunReduction, ...
    'processKMTEventsArgs', Args.processKMTEventsArgs, ...
    'TargetBasePath', Args.TargetBasePath, ...
    'TargetPath',Args.TargetPath,...
    'PerSourcesTargetPath', Args.PerSourcesTargetPath, ...
    'Site', Args.Site);

if isemptyCatalog(Matched)

    File = struct();
    File.EventNum = EventNum;
    File.CatsPath='';

else
    % Step 2: Run Gaia-KMT PM calibration
    try
    [ParScalibrated,T,DeltaPM_KMT_GAIA,OutLiersRMSvsMag,...
        PMRA_kmt_to_gaia_fit,PMDec_kmt_to_gaia_fit] = ...
        ml.scripts.gaiaAstrometryKMT(IFsys, Matched, ...
        'GaiaCatMatchedFile', Args.GaiaCatMatchedFile, ...
        'RstdTopPrc', Args.RstdTopPrc, ...
        'MaxMag', Args.MaxMag);
    catch
        fprintf('Failed to fit catalog to Gaia');
        ParScalibrated=[];
        T=[];
        DeltaPM_KMT_GAIA=[];
        OutLiersRMSvsMag=[];
        PMRA_kmt_to_gaia_fit=[];
        PMDec_kmt_to_gaia_fit=[];
    end
    % Step 3: Photometric reference source
    IndForPhotRefernce = IFsys.findClosestSource([150, 150]);

    % Step 4: Coordinates
    Coo = IFsys.CelestialCoo * 180 / pi;

    % Step 5: Package outputs
    File = struct();
    File.EventNum = EventNum;
    File.CatsPath = CatsPath;
    File.IFsys = IFsys;
    File.Obj = Obj;
    File.Matched = Matched;
    File.ParScalibrated = ParScalibrated;
    File.GaiaTable = T;
    File.DeltaPM_KMT_GAIA = DeltaPM_KMT_GAIA;
    File.OutLiersRMSvsMag = OutLiersRMSvsMag;
    File.PMRA_kmt_to_gaia_fit = PMRA_kmt_to_gaia_fit;
    File.PMDec_kmt_to_gaia_fit = PMDec_kmt_to_gaia_fit;
    File.IndForPhotRefernce = IndForPhotRefernce;
    File.FieldCenterDeg = Coo;
end
% Step 6: Save output
if Args.Save
    OutputFileName = fullfile(Args.OutputDir, sprintf('AstrometryField_%s_%s_%s.mat', num2str(EventNum),Args.Site,Args.Field));
    delete(OutputFileName)
    save(OutputFileName, 'File', '-v7.3');
    %save(OutputFileName, 'File');
    fprintf('Saved astrometry file to %s\n', OutputFileName);
end

end
