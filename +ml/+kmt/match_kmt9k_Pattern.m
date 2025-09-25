function [NewX, NewY, PatternMat, Stats, LogStr] = match_kmt9k_Pattern(ImageCat, RefTab, Args)
arguments
    ImageCat
    RefTab
    Args.XCol = 1;
    Args.YCol = 2;
    Args.MagCol = 3; 
    Args.SearchRadius = 0.5;
    Args.MaxMethod = 'max1';
    Args.Step = 0.1;
    Args.Range = [-1000.05,1000.05];
    Args.MaxMag = 17;
    Args.MinMag = 14;
    Args.XYCols = [];
    Args.ImXYCols = [];
end

LogLines = ["=== match_kmt9k_Pattern Start ==="];  % Logging header

if ~isempty(Args.ImXYCols)
    xyim = ImageCat.getCol(Args.ImXYCols);
else
    xyim = ImageCat.getXY;
end

% Filter reference stars
RefTabPattern = RefTab(RefTab(:,Args.MagCol) < Args.MaxMag & RefTab(:,Args.MagCol) > Args.MinMag, :);
if isempty(RefTabPattern)
    LogLines(end+1) = sprintf('No stars in reference catalog within magnitude limits [%.2f, %.2f].', Args.MinMag, Args.MaxMag);
    error('No stars in reference catalog within magnitude limits [%.2f, %.2f].', Args.MinMag, Args.MaxMag);
end

if numel(RefTabPattern(:,1))>1.4*numel(xyim(:,1))
    %[~, sortIdx] = sort(RefTabPattern(:,3), 'descend');
    RefTabPattern= RefTabPattern(1:ceil(1.4*numel(xyim(:,1))),:);

end


xyref = RefTabPattern(:, [Args.XCol, Args.YCol]);
D= sqrt((xyref(:,1)-xyref(:,1)').^2+(xyref(:,2)-xyref(:,2)').^2);
D(D==0)=Inf;
xyref= xyref(~any(D<10)',:);


SN_cols = ImageCat.ColNames(contains(ImageCat.ColNames, 'SN_'));
[MedianSN, IndMaxSN]= max(median(ImageCat.getCol(SN_cols)));
SNCol = ImageCat.getCol(SN_cols{IndMaxSN});

if numel(xyref(:,1))<numel(xyim(:,1))
    [~, sortIdx] = sort(SNCol, 'descend');
    SelectedInds = sortIdx(1:numel(xyref(:,1)));
    FlagSN = false(size(SNCol));
    FlagSN(SelectedInds) = true;
    xyim= xyim(FlagSN,:);
end

% SNCol = Im.CatData.getCol(SN_cols{IndMaxSN});
% SNHighLow = prctile(SNCol, [Args.SNPrctileRange]);
% ValidInds = find(SNCol >= SNHighLow(1) & SNCol <= SNHighLow(2));
% if numel(ValidInds) > Args.MaxNumOfSourceImCat
%     SN_subset = SNCol(ValidInds);
%     [~, sortIdx] = sort(SN_subset, 'descend');
%     SelectedInds = ValidInds(sortIdx(1:Args.MaxNumOfSourceImCat));
% else
%     SelectedInds = ValidInds;
% end
% FlagSN = false(size(SNCol));
% FlagSN(SelectedInds) = true;
% Im.CatData.Catalog = Im.CatData.Catalog(FlagSN,:);



% Get image coordinates
try
    II = imProc.trans.fitPattern(xyim, xyref, ...
        'StepX', Args.Step, 'StepY', Args.Step, ...
        'RangeX', Args.Range, 'RangeY', Args.Range, ...
        'SearchRadius', Args.SearchRadius, ...
        'HistRotEdges', -1:0.001:1, ...
        'MaxMethod', Args.MaxMethod,'Flip',[1,1],'HistDistEdgesRotScale',[1,600,300]);

    if ~isfield(II.Sol, 'AffineTran') || isempty(II.Sol.AffineTran{1})
        error('Pattern matching failed: Affine transformation not found.');
    end

    PatternMat = II.Sol.AffineTran{1};

    [NewX, NewY] = imUtil.cat.affine2d_transformation(...
        RefTab(:, [Args.XCol, Args.YCol]), PatternMat, '+', ...
        'ColX', 1, 'ColY', 2);

    if all(isnan(NewX)) || all(isnan(NewY))
        error('Pattern matching failed: All transformed coordinates are NaN.');
    end

    LogLines(end+1) = "------ Pattern Matched matrix -------";
    LogLines(end+1) = mat2str(PatternMat, 4);

    % Step 4: Match transformed reference to image catalog for residual stats
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

    LogLines(end+1) = sprintf("Pattern Match: %d matched of %d (%.1f%%), %d used for residual stats", ...
        Stats.NMatched, Stats.TotalRef, 100 * Stats.MatchFraction, Stats.NUsed);
    LogLines(end+1) = sprintf("Mean residuals: X = %.3f, Y = %.3f, total = %.3f px", ...
        Stats.MeanResidualX, Stats.MeanResidualY, Stats.MeanResidual);
    LogLines(end+1) = sprintf("Std  residuals: X = %.3f, Y = %.3f, total = %.3f px", ...
        Stats.StdResidualX, Stats.StdResidualY, Stats.StdResidual);
    LogLines(end+1) = sprintf("Median residuals: X = %.3f, Y = %.3f, total = %.3f px", ...
        Stats.MedianResidualX, Stats.MedianResidualY, Stats.MedianResidual);

catch ME
    NewX = nan(size(RefTab,1),1);
    NewY = nan(size(RefTab,1),1);
    PatternMat = nan(3,3);
    Stats = struct('NMatched', 0, 'TotalRef', size(RefTab,1), ...
                   'MatchFraction', 0, 'NUsed', 0, ...
                   'MeanResidual', NaN, 'StdResidual', NaN, ...
                   'MedianResidual', NaN, 'dx', [], 'dy', [], 'Residuals', []);
    LogLines(end+1) = sprintf("Pattern matching failed: %s", ME.message);
end

LogLines(end+1) = "=== match_kmt9k_Pattern End ===";
LogStr = LogLines;

end
