function report = extractImages(destRoot, pfxStart, pfxEnd, srcRoot, overwriteFiles)
%function report = extract_tar_by_prefix_range_flat(destRoot, pfxStart, pfxEnd, srcRoot, overwriteFiles)
% extract_tar_by_prefix_range_flat  Extract ###_*.tar into DEST without creating subfolders.
%
%   report = extract_tar_by_prefix_range_flat(DEST, PFXSTART, PFXEND)
%   report = extract_tar_by_prefix_range_flat(DEST, PFXSTART, PFXEND, SRC)
%   report = extract_tar_by_prefix_range_flat(DEST, PFXSTART, PFXEND, SRC, OVERWRITEFILES)
%
% Inputs:
%   DEST           Destination root folder (required). Files are extracted here.
%   PFXSTART       Numeric start prefix (e.g., 81)   -> matches files like 081_*.
%   PFXEND         Numeric end prefix (inclusive, e.g., 100).
%   SRC            Source folder with .tar files (default: '/data3/events_lowpriority').
%   OVERWRITEFILES logical; if true, allow overwriting existing files (default: false).
%
% Output (struct):
%   report.destRoot, report.srcRoot, report.range
%   report.archivesProcessed, report.archivesFailed (cellstr)

    arguments
        destRoot (1,1) string
        pfxStart (1,1) double {mustBeInteger,mustBeNonnegative,mustBeLessThanOrEqual(pfxStart,999)}
        pfxEnd   (1,1) double {mustBeInteger,mustBeNonnegative,mustBeLessThanOrEqual(pfxEnd,999)}
        srcRoot  (1,1) string = "/data3/events_lowpriority"
        overwriteFiles (1,1) logical = false
    end

    if pfxStart > pfxEnd
        error('pfxStart (%d) must be <= pfxEnd (%d).', pfxStart, pfxEnd);
    end

    if ~exist(destRoot,'dir'); mkdir(destRoot); end

    % Find matching archives by numeric 3-digit prefix
    t = dir(fullfile(srcRoot, '*.tar'));
    keep = false(numel(t),1);
    pfx  = nan(numel(t),1);
    for i = 1:numel(t)
        tok = regexp(t(i).name, '^(\d{3})_', 'tokens','once');
        if ~isempty(tok)
            p = str2double(tok{1});   % '081' -> 81
            pfx(i) = p;
            keep(i) = (p >= pfxStart) && (p <= pfxEnd);
        end
    end
    t = t(keep);
    [~,ix] = sortrows([pfx(keep), (1:nnz(keep))']);
    t = t(ix);

    report = struct('destRoot',string(destRoot), 'srcRoot',string(srcRoot), ...
                    'range',[pfxStart pfxEnd], ...
                    'archivesProcessed',{cell(0,1)}, 'archivesFailed',{cell(0,1)});

    if isempty(t)
        warning('No matching archives (%03d_* to %03d_*) found in %s', pfxStart, pfxEnd, srcRoot);
        return
    end

    % Build tar flags
    % --no-same-owner: don’t restore archived owners
    % --skip-old-files: (default) don’t overwrite existing files; change to overwrite if requested
    skipFlag = '--skip-old-files';
    if overwriteFiles
        skipFlag = '';   % tar will overwrite existing files by default
    end

    for i = 1:numel(t)
        tarPath = fullfile(t(i).folder, t(i).name);

        ok = false; errMsg = '';
        if isunix || ismac
            cmd = strtrim(sprintf('tar --no-same-owner %s -xf "%s" -C "%s"', skipFlag, tarPath, destRoot));
            [status,msg] = system(cmd);
            ok = (status == 0);
            if ~ok, errMsg = strtrim(msg); end
        end

        % Fallback to MATLAB untar (note: untar will overwrite; no "skip" mode)
        if ~ok
            if ~overwriteFiles
                warning('System tar failed or not available; falling back to MATLAB untar, which may overwrite files.');
            end
            try
                untar(tarPath, destRoot);
                ok = true;
            catch ME
                errMsg = ME.message;
            end
        end

        if ok
            fprintf('Extracted → %s into %s\n', t(i).name, destRoot);
            report.archivesProcessed{end+1,1} = t(i).name; %#ok<AGROW>
        else
            fprintf(2,'FAILED extracting %s:\n  %s\n', t(i).name, errMsg);
            report.archivesFailed{end+1,1} = t(i).name; %#ok<AGROW>
        end
    end

    fprintf('\nDone. archivesProcessed=%d, archivesFailed=%d\n', ...
        numel(report.archivesProcessed), numel(report.archivesFailed));
end
