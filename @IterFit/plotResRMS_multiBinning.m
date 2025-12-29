function Out = plotResRMS_multiBinning(IF, Args)
% plotResRMS_multiBinning
% Per-star residual RMS vs magnitude after time-binning at several cadences.
% RMS is computed from binned means with weights = Npoints per bin.
% Optional bin-level outlier rejection per star.
% Plotting includes transparent points, faint per-star connecting lines, and trends.

arguments
    IF
    Args.TimeBinSizes (1,:) double = [1,5,10,20];
    Args.closeall logical = false;
    Args.title char = '';
    Args.Plot2D logical = false;
    Args.PlotCorr logical = true;
    Args.XYtogether logical = false;

    % QC / weighting controls
    Args.MinPointsPerBin double = 5;     % drop bins with fewer than this
    Args.MinBinsPerStar double = 20;      % need at least this many good bins
    Args.RejectBinOutliers logical = true;
    Args.BinOutlierMethod char = 'median'; % 'median' or 'movmedian'
    Args.BinOutlierThresh double = 3;      % MAD-based thresh (isoutlier)

    % star-level outlier mask handling
    Args.useSameOutliers logical = true; % one mask for all τ

    % plotting controls
    Args.ConnectSources logical = true;  % connect same sources across τ
    Args.ConnectOnlyNonOutliers logical = true; % don't connect star-outliers
    Args.XJitterAmp double = 0.0;       % mag offset amplitude for τ points
    Args.PointAlpha double = 0.35;       % transparency of good points
    Args.OutlierAlpha double = 0.5;      % transparency of outlier markers
    Args.LineAlpha double = 0.08;        % faintness of connecting lines
    Args.LineWidth double = 0.7;

    % trend controls
    Args.PlotTrend logical = true;
    Args.TrendMagBinSize double = 0.25;  % mag bin for running median trend
    Args.TrendMinStarsPerBin double = 5; % min stars to define trend point
end

if Args.closeall
    close all;
end

% --- residuals in mas
[Rx, Ry] = IF.calculateResiduals;     % [Nepoch x Nsrc] in pix
Rx = Rx .* 400;                      % mas
Ry = Ry .* 400;                      % mas

JD = IF.JD(:);
M  = IF.medianFieldSource({'MAG_PSF'});  % [Nsrc x 1]
M  = M(:);

Nsrc = size(Rx,2);
Nb   = numel(Args.TimeBinSizes);

RStdX  = nan(Nsrc,Nb);
RStdY  = nan(Nsrc,Nb);
RStd2D = nan(Nsrc,Nb);
Outliers = cell(1,Nb);
BinInfo  = cell(Nsrc,Nb);

% --- helper: weighted RMS of binned means for one star
    function [r, Bgood] = weighted_rms_binned_means(t, v, binSize)
        B = timeSeries.bin.binningFast([t, v], binSize, [NaN NaN], ...
            {'MidBin', @nanmean, @tools.math.stat.rstd, @numel});
        % B = [midT, meanVal, rstdWithinBin, Npoints]

        good = ~(isnan(B(:,2)) | B(:,4) < Args.MinPointsPerBin);

        if Args.RejectBinOutliers && sum(good) >= 3
            switch lower(Args.BinOutlierMethod)
                case 'median'
                    bout = isoutlier(B(good,2), 'median', ...
                        'ThresholdFactor', Args.BinOutlierThresh);
                case 'movmedian'
                    bout = isoutlier(B(good,2), 'movmedian', 5, ...
                        'ThresholdFactor', Args.BinOutlierThresh);
                otherwise
                    error('Unknown BinOutlierMethod: %s', Args.BinOutlierMethod);
            end
            goodIdx = find(good);
            good(goodIdx(bout)) = false;
        end

        if sum(good) < Args.MinBinsPerStar
            r = NaN;
            Bgood = B(good,:);
            return;
        end

        x = B(good,2);    % binned means
        w = B(good,4);    % weights = Npoints per bin
        r = sqrt( nansum(w .* x.^2) ./ nansum(w) );

        Bgood = B(good,:);
    end

% --- compute per-star RMS for each bin size
for ib = 1:Nb
    bs = Args.TimeBinSizes(ib);
    for s = 1:Nsrc
        [RStdX(s,ib), Bxg] = weighted_rms_binned_means(JD, Rx(:,s), bs);
        [RStdY(s,ib), Byg] = weighted_rms_binned_means(JD, Ry(:,s), bs);
        BinInfo{s,ib} = struct('Bx',Bxg,'By',Byg);
    end

    RStd2D(:,ib) = sqrt(RStdX(:,ib).^2 + RStdY(:,ib).^2);

    Outliers{ib} = ml.util.iterativeOutlierDetection(RStd2D(:,ib), M, 10, ...
        'MoveMedianStep', 0.5);
end

% optionally force one common star-outlier mask
if Args.useSameOutliers
    baseOut = Outliers{1};
    for ib = 1:Nb
        Outliers{ib} = baseOut;
    end
else
    baseOut = Outliers{1};
end

% ---- plotting helpers
cols = lines(Nb);
legHandles = gobjects(1,Nb);

% x jitter per τ
xOff = linspace(-Args.XJitterAmp, Args.XJitterAmp, Nb);

    function plot_panel(yMat, yLabel)
        figure; hold on; set(gca,'YScale','log');
%        set(gca,'YScale','log');              % if not already log
        set(gca,'YTick',[1,5,10,20,50,100]);       % exact ticks you want
        yticklabels({'1','5','10','50','100'});   % optional: make labels clean
        % 1) connect sources (very faint)
        if Args.ConnectSources
            for s = 1:Nsrc
                if Args.ConnectOnlyNonOutliers && baseOut(s)
                    continue;
                end
                y = yMat(s,:);
                if all(isnan(y)), continue; end
                xs = M(s) + xOff;
                good = ~isnan(y);
                if sum(good) >= 2
                    try
                        plot(xs(good), y(good), '-', ...
                            'Color', [0 0 0 Args.LineAlpha], ...
                            'LineWidth', Args.LineWidth, ...
                            'HandleVisibility','off');
                    catch
                        % fallback for older MATLAB (no RGBA)
                        plot(xs(good), y(good), '-', ...
                            'Color', [0.5 0.5 0.5], ...
                            'LineWidth', 0.5, ...
                            'HandleVisibility','off');
                    end
                end
            end
        end

        % 2) scatter points per τ
        for ib = 1:Nb
            out = Outliers{ib};

            % good points (legend handle)
            legHandles(ib) = scatter(M(~out)+xOff(ib), yMat(~out,ib), 18, ...
                'Marker','o', ...
                'MarkerFaceColor', cols(ib,:), ...
                'MarkerEdgeColor', cols(ib,:), ...
                'MarkerFaceAlpha', Args.PointAlpha, ...
                'MarkerEdgeAlpha', Args.PointAlpha);

            % outlier points (no legend)
            scatter(M(out)+xOff(ib), yMat(out,ib), 30, ...
                'Marker','*', ...
                'MarkerEdgeColor', cols(ib,:), ...
                'MarkerEdgeAlpha', Args.OutlierAlpha, ...
                'HandleVisibility','off');
        end

        % 3) trend per τ (running median)
        if Args.PlotTrend
            magEdges   = min(M):Args.TrendMagBinSize:max(M);
            magCenters = magEdges(1:end-1) + Args.TrendMagBinSize/2;

            for ib = 1:Nb
                out = Outliers{ib};
                x = M(~out);
                y = yMat(~out,ib);

                medTrend = nan(size(magCenters));
                for k = 1:numel(magCenters)
                    inBin = x >= magEdges(k) & x < magEdges(k+1);
                    if sum(inBin) >= Args.TrendMinStarsPerBin
                        medTrend(k) = median(y(inBin),'omitnan');
                    end
                end

                plot(magCenters, medTrend, '-', ...
                    'Color', cols(ib,:), ...
                    'LineWidth', 2, ...
                    'HandleVisibility','off');
            end
        end

        xlabel('I [mag]');
        ylabel(yLabel);
        title(Args.title);
        legend(legHandles, compose('%g d bins', Args.TimeBinSizes), ...
            'Location','best');
    end

% --- XY together or separate
if Args.XYtogether
    % one combined XY cloud; use magnitude vs both X and Y in same panel
    yMatX = RStdX; yMatY = RStdY;

    figure; hold on; set(gca,'YScale','log');

    if Args.ConnectSources
        for s = 1:Nsrc
            if Args.ConnectOnlyNonOutliers && baseOut(s), continue; end
            xs = M(s) + xOff;
            yx = yMatX(s,:); yy = yMatY(s,:);
            goodx = ~isnan(yx); goody = ~isnan(yy);

            if sum(goodx) >= 2
                try
                    plot(xs(goodx), yx(goodx), '-', ...
                        'Color',[0 0 0 Args.LineAlpha], ...
                        'LineWidth',Args.LineWidth,'HandleVisibility','off');
                catch
                    plot(xs(goodx), yx(goodx), '-', ...
                        'Color',[0.5 0.5 0.5],'LineWidth',0.5,'HandleVisibility','off');
                end
            end
            if sum(goody) >= 2
                try
                    plot(xs(goody), yy(goody), '-', ...
                        'Color',[0 0 0 Args.LineAlpha], ...
                        'LineWidth',Args.LineWidth,'HandleVisibility','off');
                catch
                    plot(xs(goody), yy(goody), '-', ...
                        'Color',[0.5 0.5 0.5],'LineWidth',0.5,'HandleVisibility','off');
                end
            end
        end
    end

    for ib = 1:Nb
        out = Outliers{ib};
        legHandles(ib) = scatter(M(~out)+xOff(ib), yMatX(~out,ib), 18, ...
            'Marker','o','MarkerFaceColor',cols(ib,:), 'MarkerEdgeColor',cols(ib,:), ...
            'MarkerFaceAlpha',Args.PointAlpha,'MarkerEdgeAlpha',Args.PointAlpha);

        scatter(M(~out)+xOff(ib), yMatY(~out,ib), 18, ...
            'Marker','d','MarkerFaceColor',cols(ib,:), 'MarkerEdgeColor',cols(ib,:), ...
            'MarkerFaceAlpha',Args.PointAlpha,'MarkerEdgeAlpha',Args.PointAlpha, ...
            'HandleVisibility','off');

        scatter(M(out)+xOff(ib), yMatX(out,ib), 30, ...
            'Marker','*','MarkerEdgeColor',cols(ib,:), ...
            'MarkerEdgeAlpha',Args.OutlierAlpha,'HandleVisibility','off');

        scatter(M(out)+xOff(ib), yMatY(out,ib), 30, ...
            'Marker','*','MarkerEdgeColor',cols(ib,:), ...
            'MarkerEdgeAlpha',Args.OutlierAlpha,'HandleVisibility','off');
    end

    xlabel('I [mag]');
    ylabel('weighted rms(binned residual) [mas]');
    title(Args.title);
    legend(legHandles, compose('%g d bins', Args.TimeBinSizes), 'Location','best');

    if Args.PlotTrend
        % trend for X only (you can add Y similarly if you want)
        magEdges   = min(M):Args.TrendMagBinSize:max(M);
        magCenters = magEdges(1:end-1) + Args.TrendMagBinSize/2;
        for ib = 1:Nb
            out = Outliers{ib};
            x = M(~out);
            y = yMatX(~out,ib);

            medTrend = nan(size(magCenters));
            for k = 1:numel(magCenters)
                inBin = x >= magEdges(k) & x < magEdges(k+1);
                if sum(inBin) >= Args.TrendMinStarsPerBin
                    medTrend(k) = median(y(inBin),'omitnan');
                end
            end
            plot(magCenters, medTrend, '-', 'Color', cols(ib,:), ...
                'LineWidth', 2, 'HandleVisibility','off');
        end
    end

else
    plot_panel(RStdX, 'weighted rms(Rx) after binning [mas]');
    plot_panel(RStdY, 'weighted rms(Ry) after binning [mas]');
end

% 2D panel
if Args.Plot2D
    plot_panel(RStd2D, 'weighted rms(R) after binning [mas]');
end

% Correlation plot (smallest bin)
if Args.PlotCorr
    ib = 1; out = Outliers{ib};
    figure; hold on;
    loglog(RStdX(~out,ib), RStdY(~out,ib), '.', ...
        'Color', [0.5 0.2 0.8], 'MarkerSize', 14);
    loglog(RStdX(out,ib),  RStdY(out,ib),  '*', ...
        'Color', [0.71 0.40 0.11], 'MarkerSize', 8);
    mn = min([RStdX(:,ib); RStdY(:,ib)], [], 'omitnan');
    mx = max([RStdX(:,ib); RStdY(:,ib)], [], 'omitnan');
    plot([mn mx],[mn mx],'k-');
    xlabel('rms(Rx) [mas]');
    ylabel('rms(Ry) [mas]');
end

% --- outputs
Out = struct;
Out.TimeBinSizes = Args.TimeBinSizes;
Out.M           = M;
Out.RStdX       = RStdX;
Out.RStdY       = RStdY;
Out.RStd2D      = RStd2D;
Out.Outliers    = Outliers;
Out.BinInfo     = BinInfo;
end



% function Out = plotResRMS_multiBinning(IF, Args)
% % plotResRMS_multiBinning
% % Per-star residual RMS vs magnitude after time-binning at several cadences.
% % RMS is computed from binned means with weights = Npoints per bin.
% % Optional bin-level outlier rejection per star.
% 
% arguments
%     IF
%     Args.TimeBinSizes (1,:) double = [5 10 20];
%     Args.closeall logical = false;
%     Args.title char = '';
%     Args.Plot2D logical = false;
%     Args.PlotCorr logical = true;
%     Args.XYtogether logical = false;
% 
%     % QC / weighting controls
%     Args.MinPointsPerBin double = 2;   % drop bins with fewer than this
%     Args.MinBinsPerStar double = 2;    % need at least this many good bins
%     Args.RejectBinOutliers logical = true;
%     Args.BinOutlierMethod char = 'median'; % 'median' or 'movmedian'
%     Args.BinOutlierThresh double = 3;      % MAD-based thresh (isoutlier)
% 
%     % star-level outlier mask handling
%     Args.useSameOutliers logical = true;   % one mask for all τ
% end
% 
% if Args.closeall
%     close all;
% end
% 
% % --- residuals in mas
% [Rx, Ry] = IF.calculateResiduals;     % [Nepoch x Nsrc] (pix)
% Rx = Rx .* 400;                      % mas
% Ry = Ry .* 400;                      % mas
% 
% JD = IF.JD(:);
% M  = IF.medianFieldSource({'MAG_PSF'});  % [Nsrc x 1]
% M  = M(:);
% 
% Nsrc = size(Rx,2);
% Nb   = numel(Args.TimeBinSizes);
% 
% RStdX  = nan(Nsrc,Nb);
% RStdY  = nan(Nsrc,Nb);
% RStd2D = nan(Nsrc,Nb);
% Outliers = cell(1,Nb);
% BinInfo  = cell(Nsrc,Nb); % store per-star per-bin details (optional)
% 
% % --- helper: weighted RMS of binned means for one star
%     function [r, Bgood] = weighted_rms_binned_means(t, v, binSize)
%         B = timeSeries.bin.binningFast([t, v], binSize, [NaN NaN], ...
%             {'MidBin', @nanmean, @tools.math.stat.rstd, @numel});
%         % B = [midT, meanVal, rstdWithinBin, Npoints]
% 
%         % basic bin validity
%         good = ~(isnan(B(:,2)) | B(:,4) < Args.MinPointsPerBin);
% 
%         % optional: reject bin-level outliers in the binned means
%         if Args.RejectBinOutliers && sum(good) >= 3
%             switch lower(Args.BinOutlierMethod)
%                 case 'median'
%                     bout = isoutlier(B(good,2), 'median', ...
%                         'ThresholdFactor', Args.BinOutlierThresh);
%                 case 'movmedian'
%                     bout = isoutlier(B(good,2), 'movmedian', 5, ...
%                         'ThresholdFactor', Args.BinOutlierThresh);
%                 otherwise
%                     error('Unknown BinOutlierMethod: %s', Args.BinOutlierMethod);
%             end
%             goodIdx = find(good);
%             good(goodIdx(bout)) = false;
%         end
% 
%         if sum(good) < Args.MinBinsPerStar
%             r = NaN;
%             Bgood = B(good,:);
%             return;
%         end
% 
%         x = B(good,2);      % binned mean residuals
%         w = B(good,4);      % weights = Npoints per bin
% 
%         % weighted RMS around 0 (residuals already mean~0)
%         r = sqrt( nansum(w .* x.^2) ./ nansum(w) );
%         Bgood = B(good,:);
%     end
% 
% % --- compute per-star RMS for each bin size
% for ib = 1:Nb
%     bs = Args.TimeBinSizes(ib);
%     for s = 1:Nsrc
%         [RStdX(s,ib), Bxg] = weighted_rms_binned_means(JD, Rx(:,s), bs);
%         [RStdY(s,ib), Byg] = weighted_rms_binned_means(JD, Ry(:,s), bs);
%         BinInfo{s,ib} = struct('Bx',Bxg,'By',Byg); %#ok<AGROW>
%     end
% 
%     RStd2D(:,ib) = sqrt(RStdX(:,ib).^2 + RStdY(:,ib).^2);
% 
%     % star-level outliers vs mag (same logic as your plotResRMS)
%     Outliers{ib} = ml.util.iterativeOutlierDetection(RStd2D(:,ib), M, 10, ...
%         'MoveMedianStep', 0.5);
% end
% 
% % optionally force one common star-outlier mask
% if Args.useSameOutliers
%     baseOut = Outliers{1};
%     for ib = 1:Nb
%         Outliers{ib} = baseOut;
%     end
% end
% 
% % --- plotting
% cols = lines(Nb);
% legHandles = gobjects(1,Nb);
% 
% if Args.XYtogether
%     figure; hold on;
%     for ib = 1:Nb
%         out = Outliers{ib};
% 
%         % good stars (legend handle)
%         legHandles(ib) = semilogy(M(~out), RStdX(~out,ib), '.', ...
%             'Color', cols(ib,:), 'MarkerSize', 14);
% 
%         % outlier stars (no legend)
%         semilogy(M(out),  RStdX(out,ib),  '*', ...
%             'Color', cols(ib,:), 'MarkerSize', 8, ...
%             'HandleVisibility','off');
% 
%         semilogy(M(~out), RStdY(~out,ib), 'd', ...
%             'Color', cols(ib,:), 'MarkerSize', 10, ...
%             'HandleVisibility','off');
% 
%         semilogy(M(out),  RStdY(out,ib),  'o', ...
%             'Color', cols(ib,:), 'MarkerSize', 6, ...
%             'HandleVisibility','off');
%     end
%     xlabel('I [mag]');
%     ylabel('weighted rms(binned residual) [mas]');
%     title(Args.title);
%     legend(legHandles, compose('%g d bins', Args.TimeBinSizes), 'Location','best');
% 
% else
%     % X panel
%     figure; hold on;
%     for ib = 1:Nb
%         out = Outliers{ib};
%         legHandles(ib) = semilogy(M(~out), RStdX(~out,ib), '.', ...
%             'Color', cols(ib,:), 'MarkerSize', 14);
%         semilogy(M(out),  RStdX(out,ib),  '*', ...
%             'Color', cols(ib,:), 'MarkerSize', 8, ...
%             'HandleVisibility','off');
%     end
%     xlabel('I [mag]');
%     ylabel('weighted rms(Rx) after binning [mas]');
%     title(Args.title);
%     legend(legHandles, compose('%g d bins', Args.TimeBinSizes), 'Location','best');
% 
%     % Y panel
%     figure; hold on;
%     for ib = 1:Nb
%         out = Outliers{ib};
%         semilogy(M(~out), RStdY(~out,ib), '.', ...
%             'Color', cols(ib,:), 'MarkerSize', 14, ...
%             'HandleVisibility','off');
%         semilogy(M(out),  RStdY(out,ib),  '*', ...
%             'Color', cols(ib,:), 'MarkerSize', 8, ...
%             'HandleVisibility','off');
%     end
%     xlabel('I [mag]');
%     ylabel('weighted rms(Ry) after binning [mas]');
%     title(Args.title);
%     legend(legHandles, compose('%g d bins', Args.TimeBinSizes), 'Location','best');
% end
% 
% % 2D RMS panel
% if Args.Plot2D
%     figure; hold on;
%     for ib = 1:Nb
%         out = Outliers{ib};
%         semilogy(M(~out), RStd2D(~out,ib), '.', ...
%             'Color', cols(ib,:), 'MarkerSize', 14, ...
%             'HandleVisibility','off');
%         semilogy(M(out),  RStd2D(out,ib),  '*', ...
%             'Color', cols(ib,:), 'MarkerSize', 8, ...
%             'HandleVisibility','off');
%     end
%     xlabel('I [mag]');
%     ylabel('weighted rms(R) after binning [mas]');
%     title(Args.title);
%     legend(legHandles, compose('%g d bins', Args.TimeBinSizes), 'Location','best');
% end
% 
% % Correlation plot (smallest bin)
% if Args.PlotCorr
%     ib = 1; out = Outliers{ib};
%     figure; hold on;
%     loglog(RStdX(~out,ib), RStdY(~out,ib), '.', ...
%         'Color', [0.5 0.2 0.8], 'MarkerSize', 14);
%     loglog(RStdX(out,ib),  RStdY(out,ib),  '*', ...
%         'Color', [0.71 0.40 0.11], 'MarkerSize', 8);
%     mn = min([RStdX(:,ib); RStdY(:,ib)], [], 'omitnan');
%     mx = max([RStdX(:,ib); RStdY(:,ib)], [], 'omitnan');
%     plot([mn mx],[mn mx],'k-');
%     xlabel('rms(Rx) [mas]');
%     ylabel('rms(Ry) [mas]');
% end
% 
% % --- outputs
% Out = struct;
% Out.TimeBinSizes = Args.TimeBinSizes;
% Out.M           = M;
% Out.RStdX       = RStdX;
% Out.RStdY       = RStdY;
% Out.RStd2D      = RStd2D;
% Out.Outliers    = Outliers;
% Out.BinInfo     = BinInfo;
% end
