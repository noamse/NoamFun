function [NewX,NewY,PatternMat,Stats] = match_kmt9k_Pattern(ImageCat, RefTab, Args)
arguments
    ImageCat
    RefTab
    Args.XCol = 1;
    Args.YCol = 2;
    Args.MagCol = 3; 
    Args.SearchRadius = 1;
    Args.MaxMethod = 'max1';
    Args.Step = 0.1;
    Args.Range = [-1000.05,1000.05];
    Args.MaxMag = 17;
    Args.MinMag = 14;
    Args.XYCols = [];
    Args.ImXYCols=[];
end

% Filter reference stars
RefTabPattern = RefTab(RefTab(:,Args.MagCol) < Args.MaxMag & RefTab(:,Args.MagCol) > Args.MinMag, :);
if isempty(RefTabPattern)
    error('No stars in reference catalog within magnitude limits [%.2f, %.2f].', Args.MinMag, Args.MaxMag);
end
xyref = RefTabPattern(:, [Args.XCol, Args.YCol]);

% Get image coordinates
if ~isempty(Args.ImXYCols)
    xyim = ImageCat.getCol(Args.ImXYCols);
else
    xyim = ImageCat.getXY;
end

% Run pattern matching
try
    II = imProc.trans.fitPattern(xyim, xyref, ...
        'StepX', Args.Step, 'StepY', Args.Step, ...
        'RangeX', Args.Range, 'RangeY', Args.Range, ...
        'SearchRadius', Args.SearchRadius, ...
        'HistRotEdges', -1:0.001:1, ...
        'MaxMethod', Args.MaxMethod);

    if ~isfield(II.Sol, 'AffineTran') || isempty(II.Sol.AffineTran{1})
        error('Pattern matching failed: Affine transformation not found.');
    end

    PatternMat = II.Sol.AffineTran{1};

    % Apply transformation
    [NewX, NewY] = imUtil.cat.affine2d_transformation(...
        RefTab(:, [Args.XCol, Args.YCol]), PatternMat, '+', ...
        'ColX', 1, 'ColY', 2);

    % Check for NaNs
    if all(isnan(NewX)) || all(isnan(NewY))
        error('Pattern matching failed: All transformed coordinates are NaN.');
    end

    disp('------ Pattern Matched matrix -------')
    disp(PatternMat)
    

        %% Step 4: Match transformed reference to image catalog for residual stats
    transRef = [NewX, NewY];
    imgPos = xyim;

    [idx, dist] = knnsearch(imgPos, transRef);
    valid = ~isnan(NewX) & ~isnan(NewY) & dist < Args.SearchRadius;

    dx = transRef(valid,1) - imgPos(idx(valid),1);
    dy = transRef(valid,2) - imgPos(idx(valid),2);
    dr = sqrt(dx.^2 + dy.^2);
    
    Stats.MeanResidualX   = mean(dx);
    Stats.MeanResidualY   = mean(dy);
    Stats.StdResidualX    = std(dx);
    Stats.StdResidualY    = std(dy);
    Stats.MedianResidualX = median(dx);
    Stats.MedianResidualY = median(dy);

    Stats.NMatched = sum(valid);
    Stats.TotalRef = size(transRef,1);
    Stats.MatchFraction = Stats.NMatched / Stats.TotalRef;
    Stats.NUsed = numel(dr);
    Stats.MeanResidual = mean(dr);
    Stats.StdResidual = std(dr);
    Stats.MedianResidual = median(dr);
    Stats.dx = dx;
    Stats.dy = dy;
    Stats.Residuals = dr;
fprintf('Pattern Match: %d matched of %d (%.1f%%), %d used for residual stats\n', ...
    Stats.NMatched, Stats.TotalRef, 100 * Stats.MatchFraction, Stats.NUsed);
fprintf('Mean residuals: X = %.3f, Y = %.3f, total = %.3f px\n', ...
    Stats.MeanResidualX, Stats.MeanResidualY, Stats.MeanResidual);
fprintf('Std  residuals: X = %.3f, Y = %.3f, total = %.3f px\n', ...
    Stats.StdResidualX, Stats.StdResidualY, Stats.StdResidual);
fprintf('Median residuals: X = %.3f, Y = %.3f, total = %.3f px\n', ...
    Stats.MedianResidualX, Stats.MedianResidualY, Stats.MedianResidual);

catch ME
    % Return empty to indicate failure
    NewX = nan(size(RefTab,1),1);
    NewY = nan(size(RefTab,1),1);
    PatternMat = nan(3,3);
        Stats = struct('NMatched', 0, 'TotalRef', size(RefTab,1), ...
                   'MatchFraction', 0, 'NUsed', 0, ...
                   'MeanResidual', NaN, 'StdResidual', NaN, ...
                   'MedianResidual', NaN, 'dx', [], 'dy', [], 'Residuals', []);
    warning('Pattern matching failed: %s', ME.message);
end
Stat=1;
end