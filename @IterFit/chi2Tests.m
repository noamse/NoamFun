function [Chi2X,Chi2Y,NbinX,NbinY] = chi2Tests(IF,Args)
arguments
    IF;
    Args.TimeBinSize = 10;
end
[Rx,Ry] =IF.calculateResiduals;
Chi2X = zeros(IF.Nsrc,1);
Chi2Y = zeros(IF.Nsrc,1);
NbinX = zeros(IF.Nsrc,1);
NbinY = zeros(IF.Nsrc,1);

for Isrc = 1:IF.Nsrc
    Rxsrc = Rx(:,Isrc);
    Rysrc = Ry(:,Isrc);
    Out = isoutlier(Rxsrc,1) | isoutlier(Rysrc,1);
    Bx = timeSeries.bin.binningFast([IF.JD(~Out)-2450000, Rxsrc(~Out)], Args.TimeBinSize,[NaN NaN],{'MidBin', @nanmean, @tools.math.stat.rstd,@numel});
    Bx(Bx(:,3)==0,3) = Inf; FlagX = ~(Bx(:,2)==0 | isnan(Bx(:,2)) | Bx(:,4)<2);
    By = timeSeries.bin.binningFast([IF.JD(~Out)-2450000, Rysrc(~Out)], Args.TimeBinSize,[NaN NaN],{'MidBin', @nanmean, @tools.math.stat.rstd,@numel});
    By(By(:,3)==0,3) = Inf; FlagY = ~(By(:,2)==0 | isnan(By(:,2)) | By(:,4)<2);
    Chi2X(Isrc) = sum((Bx(FlagX,2)./(Bx(FlagX ,3)./sqrt(Bx(FlagX,4)))).^2);
    Chi2Y(Isrc) = sum((By(FlagY,2)./(By(FlagY ,3)./sqrt(By(FlagY,4)))).^2);
    NbinX(Isrc) = sum(FlagX);
    NbinY(Isrc) = sum(FlagY);
end

%{
ax1 = subplot(2,1,1);
OutX = isoutlier(Rx,1);
Bx = timeSeries.bin.binningFast([IF.JD(~Out)-2450000, Rx(~Out)], Args.TimeBinSize,[NaN NaN],{'MidBin', @nanmean, @tools.math.stat.rstd,@numel});
Bx(Bx(:,3)==0,3) = Inf; FlagX = ~(Bx(:,2)==0 | isnan(Bx(:,2)) | Bx(:,4)<2);
scatter(IF.JD-2450000,Rx,5,'o','filled','MarkerFaceAlpha',.2,'MarkerEdgeAlpha',.2); ylabel('Rx')

hold on;

errorbar(Bx(FlagX ,1),Bx(FlagX ,2),Bx(FlagX ,3)./sqrt(Bx(FlagX,4)),'.');
ylim([-50,50])

ax2 = subplot(2,1,2);
OutY = isoutlier(Ry,2);
By = timeSeries.bin.binningFast([IF.JD(~Out)-2450000, Ry(~Out)], Args.TimeBinSize,[NaN NaN],{'MidBin', @nanmean, @tools.math.stat.rstd,@numel});
By(By(:,3)==0,3) = Inf; FlagY = ~(By(:,2)==0 | isnan(By(:,2)) | By(:,4)<2);
scatter(IF.JD-2450000,Ry,5,'o','filled','MarkerFaceAlpha',.2,'MarkerEdgeAlpha',.2); ylabel('Ry')

hold on;
ylim([-50,50])
errorbar(By(FlagY ,1),By(FlagY ,2),By(FlagY ,3)./sqrt(By(FlagY,4)),'.');





%}