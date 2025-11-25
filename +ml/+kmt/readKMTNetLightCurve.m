function [lcTbl, meta] = readKMTNetLightCurve(eventNum, field, nameValueArgs)
% readKMTNetLightCurve  Download and read a KMTNet lightcurve (.pysis),
% convert HJD->JD, and save a trimmed txt with JD mag mag_err.
%
% Outputs:
%   lcTbl : table with columns JD, mag, mag_err
%   meta  : struct with URL, local filenames, etc.

arguments
    eventNum
    field (1,1) double {mustBeInteger, mustBeNonnegative}
    nameValueArgs.obs (1,1) string = "KMTC"
    nameValueArgs.band (1,1) string = "I"
    nameValueArgs.outdir (1,1) string = "/home/noamse/KMT/data/CatsKMT/lightcurves/"
    nameValueArgs.overwrite (1,1) logical = false
    nameValueArgs.opts = []   % ImportOptions object or []
end

obs       = nameValueArgs.obs;
band      = nameValueArgs.band;
outdir    = nameValueArgs.outdir;
overwrite = nameValueArgs.overwrite;
opts      = nameValueArgs.opts;

% -------- normalize eventNum --------
eventNumStr = string(eventNum);
eventNumStr = strip(eventNumStr);
eventNumStr = erase(eventNumStr, "KB");
eventNumStr = pad(eventNumStr, 6, "left", "0");

yy = str2double(extractBetween(eventNumStr, 1, 2));
yearFull = 2000 + yy;
eventID = "KB" + eventNumStr;

% -------- format field --------
fieldStr = sprintf("%02d", field);

% remote filename on server
remoteFile = obs + fieldStr + "_" + band + ".pysis";

% URL
baseURL = sprintf("https://kmtnet.kasi.re.kr/ulens/event/%d/data/%s/pysis/", ...
                  yearFull, eventID);
url = baseURL + remoteFile;

% -------- local filenames --------
% download name (keep as pysis locally)
localPysisBase = "kmt" + eventNumStr + "_" + fieldStr + "_lightcurve.pysis";
localPysisFile = fullfile(outdir, localPysisBase);

% output txt name
localTxtBase = "kmt" + eventNumStr + "_" + fieldStr + "_lightcurve.txt";
localTxtFile = fullfile(outdir, localTxtBase);

if ~isfolder(outdir)
    mkdir(outdir);
end

% -------- download --------
if ~isfile(localPysisFile) || overwrite
    try
        websave(localPysisFile, url);
    catch ME
        error("Failed to download lightcurve.\nURL: %s\nMATLAB error: %s", url, ME.message);
    end
end

% -------- read .pysis --------
if isempty(opts)
    opts = detectImportOptions(localPysisFile, "FileType","text");
    opts.Delimiter = {' ', '\t'};
    opts.ConsecutiveDelimitersRule = "join";
    opts.CommentStyle = '#';
    opts.ExtraColumnsRule = "ignore";
    opts.EmptyLineRule    = "read";
end

rawTbl = readtable(localPysisFile, opts);

% -------- find required columns robustly --------
vn = lower(string(rawTbl.Properties.VariableNames));

iHJD    = find(vn == "hjd", 1);
iMag    = find(vn == "mag", 1);
iMagErr = find(contains(vn,"mag_err") | vn=="magerr", 1);

if isempty(iHJD) || isempty(iMag) || isempty(iMagErr)
    % fallback to standard pysis order if header is commented out:
    % 1:HJD 2:dflux 3:flux_err 4:mag 5:mag_err ...
    if width(rawTbl) < 5
        error("pysis file has <5 columns, can't apply fallback. Found %d columns.", width(rawTbl));
    end
    iHJD = 1;
    iMag = 4;
    iMagErr = 5;
end

HJD     = rawTbl{:, iHJD};
mag     = rawTbl{:, iMag};
mag_err = rawTbl{:, iMagErr};

HJD = rawTbl{:, iHJD};
mag = rawTbl{:, iMag};
mag_err = rawTbl{:, iMagErr};

% -------- convert HJD -> JD --------
JD = HJD + 2450000;

% final table
lcTbl = table(JD, mag, mag_err);

% -------- save txt (3 columns, whitespace-separated) --------
% No header requested by you, so write just numeric columns.
writematrix(lcTbl{:,:}, localTxtFile, "Delimiter", " ");

% -------- meta --------
if nargout > 1
    meta = struct();
    meta.url = url;
    meta.localPysisFile = localPysisFile;
    meta.localTxtFile = localTxtFile;
    meta.eventID = eventID;
    meta.year = yearFull;
    meta.obs = obs;
    meta.field = field;
    meta.band = band;
else
    meta = [];
end

end
