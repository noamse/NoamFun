function runEventBatch(FieldNum,Args)
    arguments
        FieldNum;
        Args.Site = 'CTIO';
        Args.FieldToAvoid= '';
        Args.PathToImagesDirs = '/data1/noamse/KMT/data/images/events_highpriority/';
        Args.TargetBasePath ='/home/noamse/KMT/data/Results/';
    end
    % Default argument handling
    Site= Args.Site;
    FieldToAvoid = Args.FieldToAvoid;

    fprintf("==========================================\n");
    fprintf("🔧 KMT Event Processing Launcher\n");
    fprintf("------------------------------------------\n");
    fprintf("  📌 Event number     : %s\n", FieldNum);
    fprintf("  🛰️  Site             : %s\n", Site);
    fprintf("  ❌ Field to avoid    : %s\n", FieldToAvoid);
    fprintf("  ⏱️  Start time        : %s\n", datestr(now, 'yyyy-mm-dd HH:MM:SS'));
    fprintf("==========================================\n");

    % ========= RUN FIELD PROCESSING IN MATLAB =========
    fprintf("🚀 Running MATLAB: processKMTEventField...\n");
    [out,ResFlagProcess] = ml.scripts.processKMTEventField(FieldNum, 'Site', Site, 'FieldToAvoid', FieldToAvoid,'PathToImagesDirs',Args.PathToImagesDirs,'TargetBasePath',Args.TargetBasePath);
    disp(out);
    TargetLogPath = out;  % assuming 'out' is a string path

    fprintf("✅ MATLAB finished. Top-level log path:\n   %s\n", TargetLogPath);

    % ========= IDENTIFY RESULT DIRECTORIES =========
    ResultBaseDir = fullfile(Args.TargetBasePath, sprintf('kmt%d/', FieldNum), Site);
    if ~isfolder(ResultBaseDir)
        error('[ERROR] Result directory does not exist: %s', ResultBaseDir);
    end

    d = dir(ResultBaseDir);
    isSubDir = [d.isdir] & ~ismember({d.name}, {'.', '..'});
    FieldDirs = fullfile(ResultBaseDir, {d(isSubDir).name});
    FieldDirs = FieldDirs(ResFlagProcess);
    NumFields = numel(FieldDirs);

    fprintf("==========================================\n");
    fprintf("📂 Results path       : %s\n", ResultBaseDir);
    fprintf("🔍 Found %d fields to process:\n", NumFields);
    for i = 1:NumFields
        fprintf("   └─ %s\n", basename(FieldDirs{i}));
    end
    fprintf("==========================================\n");

    % ========= LOOP OVER FIELDS & RUN ASTROMETRY =========
    for i = 1:NumFields
        fieldDir = FieldDirs{i};

        if ~isfolder(fieldDir), continue; end
        fieldName = basename(fieldDir);
        ut.sendTelegram(['Running astrometry on Field: ' fieldDir , 'Event ' num2str(FieldNum), '  ' num2str(i) ' out of ' num2str(NumFields)])
        fprintf("------------------------------------------\n");
        fprintf(" Running astrometry for field: %s\n", fieldName);
        fprintf("   ➤ Directory: '%s/'\n", fieldDir);
        try
            FilePath = ml.scripts.runAstrometryField(FieldNum, 'Field', fieldName, 'TargetPath', [fieldDir '/']);
            disp(FilePath);
            fprintf("   ✅ Astrometry result file: %s\n", FilePath);
        catch 
            fprintf(" Astrometry Failed : %d\n", FieldNum);
            ut.sendTelegram(['Failed to run astrometry on Field: ' fieldDir , 'Event ' num2str(FieldNum), '  ' num2str(i) ' out of ' num2str(NumFields)])
            
        end

        
    end
    if exist('FilePath', 'var')
        ut.sendTelegram(['Finish Field ',num2str(FieldNum),'! File Path = ',FilePath])
    else
        ut.sendTelegram(['Failed to finish Field ' num2str(FieldNum)])
    end
    fprintf("==========================================\n");
    fprintf("✅ All fields completed.\n");
    fprintf("📅 Done at: %s\n", datestr(now, 'yyyy-mm-dd HH:MM:SS'));
    fprintf("==========================================\n");
end

function name = basename(path)
    [~, name, ext] = fileparts(path);
    name = [name ext];
end