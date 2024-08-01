function [Bx,By] = plotSource(IF,SourceInd,Args)


arguments
    IF;
    SourceInd=1;
    Args.CloseAll = true;
    Args.SourceInd= [];
    Args.Color = [0.5,0.2,0.8];
    Args.plotXYhist = false;
    Args.TimeBinSize =10;
    Args.plotBinnedHist = false;
    Args.Coo = [];
    Args.PlotPlx = false;
    Args.PlotMag =true;
end


TS = IF.getTimeSeriesField(SourceInd,{'X','Y','MAG_PSF'});


if Args.CloseAll
    close all;
end
figure;



%ModelX = IF.AsX * IF.ParS(:,SourceInd);
%ModelY = IF.AsY * IF.ParS(:,SourceInd);
ModelX = IF.AsX * IF.ParS;
ModelY = IF.AsY * IF.ParS;
 if IF.Chromatic
     pa = IF.getTimeSeriesField(1,{'pa'});
     secz= IF.getTimeSeriesField(1,{'pa'});
     [Acx,Acy]   = generateChromDesignMat(IF);
     ParC=IF.ParC;
     if IF.Chrom2D
        ParC(1,:) = ParC(1,:).*sin(pa').*secz';
        ParC(2,:) = ParC(2,:).*cos(pa').*secz';
        ParC(isnan(ParC))=0;
        ModelX = ModelX + (Acx * ParC)';
        ModelY = ModelY + (Acy * ParC)';
     else
        %ParCx = ParC.*sin(pa').*secz';
        %ParCy = ParC.*cos(pa').*secz';
        ParCx = ParC.*sin(pa');
        ParCy = ParC.*cos(pa');
        ParCx (isnan(ParCx ))=0;
        ParCy (isnan(ParCy ))=0;
        ModelX = ModelX + (Acx * ParCx)';
        ModelY = ModelY + (Acy * ParCy)';
     end
 end
ModelX = ModelX(:,SourceInd);
ModelY = ModelY(:,SourceInd);
AffineX = (IF.AeX * IF.ParE)';
AffineX = -AffineX(:,SourceInd);
AffineY = (IF.AeY * IF.ParE)';
AffineY = -AffineY(:,SourceInd);

if Args.PlotMag
    ax1=subplot(3,1,1);
    plot(IF.JD-2450000,TS(:,3),'.','Color',Args.Color);
    ylabel('I [mag]','interpreter','latex')
    set(gca,'YDir','reverse')
    ax2= subplot(3,1,2);
    plot(IF.JD-2450000,TS(:,1)+AffineX,'.','Color',Args.Color);
    hold on;
    plot(IF.JD-2450000,ModelX);
    ylabel('X [pix]','interpreter','latex')
    hold off;
    ax3= subplot(3,1,3);
    plot(IF.JD-2450000,TS(:,2)+AffineY,'.','Color',Args.Color);
    hold on;
    plot(IF.JD-2450000,ModelY);
    ylabel('Y [pix]','interpreter','latex')
    xlabel('JD','interpreter','latex');
    linkaxes([ax1,ax2,ax3],'x');
else
    
    ax1= subplot(2,1,1);
    plot(IF.JD-2450000,TS(:,1)+AffineX,'.','Color',Args.Color);
    hold on;
    plot(IF.JD-2450000,ModelX);
    ylabel('X [pix]','interpreter','latex')
    hold off;
    ax2= subplot(2,1,2);
    plot(IF.JD-2450000,TS(:,2)+AffineY,'.','Color',Args.Color);
    hold on;
    plot(IF.JD-2450000,ModelY);
    ylabel('Y [pix]','interpreter','latex')
    xlabel('JD','interpreter','latex');
    linkaxes([ax1,ax2],'x');
end



OutMag=isoutlier(TS(:,3),"movmedian",Args.TimeBinSize);
Ytag = TS(:,2)+AffineY;
DY = (Ytag - ModelY);
OutY=isoutlier(DY,1);
Xtag = TS(:,1)+AffineX;
DX = (Xtag - ModelX);

OutX=isoutlier(DX,1);
Out = (OutX) | (OutY) | (OutMag);

figure;

if Args.PlotMag
    ax1 = subplot(3,1,1);
    %DX = (H*CM.pm_x(:,Sind)-CM.MS.Data.X(:,Sind)).*CM.pix2mas;
    BMag = timeSeries.bin.binningFast([IF.JD(~Out)-2450000, TS(~Out,3)], Args.TimeBinSize,[NaN NaN],{'MidBin', @nanmean, @tools.math.stat.rstd,@numel});
    FlagMag = ~(BMag(:,2)==0 | isnan(BMag(:,2)));
    errorbar(BMag(FlagMag,1),BMag(FlagMag,2),BMag(FlagMag,3)./sqrt(BMag(FlagMag,4)),'.')
    ylabel('I','interpreter','latex')
    xlabel('JD','interpreter','latex');
    set(gca,'YDir','reverse')
    
    ax2 = subplot(3,1,2);
    Bx = timeSeries.bin.binningFast([IF.JD(~Out)-2450000, Xtag(~Out) ], Args.TimeBinSize,[NaN NaN],{'MidBin', @nanmean, @tools.math.stat.rstd,@numel});
    Bx(Bx(:,3)==0,3) = Inf;
    FlagX = ~(Bx(:,2)==0 | isnan(Bx(:,2)) | Bx(:,4)<2);
    errorbar(Bx(FlagX ,1),Bx(FlagX ,2),Bx(FlagX ,3)./sqrt(Bx(FlagX,4)),'.');
    hold on;
    %plot(IF.JD-2450000,ModelX,'o','Color',[0.7, 0.2, 0.5]);
    scatter1= scatter(IF.JD-2450000,ModelX);%,'Color',[0.7, 0.2, 0.5]);
    alpha(scatter1,.05)
    BmodelX = timeSeries.bin.binningFast([IF.JD(~Out)-2450000, ModelX(~Out) ], Args.TimeBinSize,[NaN NaN],{'MidBin', @nanmean, @tools.math.stat.rstd,@numel});
    BmodelX(BmodelX(:,3)==0,3) = Inf;
    errorbar(BmodelX(FlagX ,1),BmodelX(FlagX ,2),BmodelX(FlagX ,3)./sqrt(BmodelX(FlagX,4)),'.');
    ylabel('X [pix]','interpreter','latex')
    xlabel('JD','interpreter','latex');
    
    ax3 = subplot(3,1,3);
    
    By = timeSeries.bin.binningFast([IF.JD(~Out)-2450000, Ytag(~Out)], Args.TimeBinSize,[NaN NaN],{'MidBin', @nanmean, @tools.math.stat.rstd,@numel});
    By(By(:,3)==0,3) = Inf;
    FlagY = ~(By(:,2)==0 | isnan(By(:,2))| By(:,4)<2);
    errorbar(By(FlagY ,1),By(FlagY ,2),By(FlagY ,3)./sqrt(By(FlagY,4)),'.')
    hold on;
    %plot(IF.JD-2450000,ModelY,'o','Color',[0.7, 0.2, 0.5]);
    scatter1= scatter(IF.JD-2450000,ModelY);%,'Color',[0.7, 0.2, 0.5]);
    alpha(scatter1,.05)
    BmodelY = timeSeries.bin.binningFast([IF.JD(~Out)-2450000, ModelY(~Out) ], Args.TimeBinSize,[NaN NaN],{'MidBin', @nanmean, @tools.math.stat.rstd,@numel});
    BmodelY(BmodelY(:,3)==0,3) = Inf;
    errorbar(BmodelY(FlagY ,1),BmodelY(FlagY ,2),BmodelX(FlagY ,3)./sqrt(BmodelY(FlagY,4)),'.');
    
    ylabel('Y [pix]','interpreter','latex')
    xlabel('JD','interpreter','latex');
    
    linkaxes([ax1,ax2,ax3],'x');
    
else
    ax1 = subplot(2,1,1);
    Bx = timeSeries.bin.binningFast([IF.JD(~Out)-2450000, Xtag(~Out) ], Args.TimeBinSize,[NaN NaN],{'MidBin', @nanmean, @tools.math.stat.rstd,@numel});
    Bx(Bx(:,3)==0,3) = Inf;
    FlagX = ~(Bx(:,2)==0 | isnan(Bx(:,2)) | Bx(:,4)<2);
    errorbar(Bx(FlagX ,1),Bx(FlagX ,2),Bx(FlagX ,3)./sqrt(Bx(FlagX,4)),'.');
    hold on;
    %plot(IF.JD-2450000,ModelX,'o','Color',[0.7, 0.2, 0.5]);
    scatter1= scatter(IF.JD-2450000,ModelX);%,'Color',[0.7, 0.2, 0.5]);
    alpha(scatter1,.05)
    BmodelX = timeSeries.bin.binningFast([IF.JD(~Out)-2450000, ModelX(~Out) ], Args.TimeBinSize,[NaN NaN],{'MidBin', @nanmean, @tools.math.stat.rstd,@numel});
    BmodelX(BmodelX(:,3)==0,3) = Inf;
    errorbar(BmodelX(FlagX ,1),BmodelX(FlagX ,2),BmodelX(FlagX ,3)./sqrt(BmodelX(FlagX,4)),'.');
    ylabel('X [pix]','interpreter','latex')
    xlabel('JD','interpreter','latex');
    
    ax2 = subplot(2,1,2);
    By = timeSeries.bin.binningFast([IF.JD(~Out)-2450000, Ytag(~Out)], Args.TimeBinSize,[NaN NaN],{'MidBin', @nanmean, @tools.math.stat.rstd,@numel});
    By(By(:,3)==0,3) = Inf;
    FlagY = ~(By(:,2)==0 | isnan(By(:,2))| By(:,4)<2);
    errorbar(By(FlagY ,1),By(FlagY ,2),By(FlagY ,3)./sqrt(By(FlagY,4)),'.')
    hold on;
    %plot(IF.JD-2450000,ModelY,'o','Color',[0.7, 0.2, 0.5]);
    scatter1= scatter(IF.JD-2450000,ModelY);%,'Color',[0.7, 0.2, 0.5]);
    alpha(scatter1,.05)
    BmodelY = timeSeries.bin.binningFast([IF.JD(~Out)-2450000, ModelY(~Out) ], Args.TimeBinSize,[NaN NaN],{'MidBin', @nanmean, @tools.math.stat.rstd,@numel});
    BmodelY(BmodelY(:,3)==0,3) = Inf;
    errorbar(BmodelY(FlagY ,1),BmodelY(FlagY ,2),BmodelX(FlagY ,3)./sqrt(BmodelY(FlagY,4)),'.');
    ylabel('Y [pix]','interpreter','latex')
    xlabel('JD','interpreter','latex');

    linkaxes([ax1,ax2],'x');
end
%Plot residuals
figure;
[Rx,Ry] =IF.calculateResiduals;
Rx = Rx(:,SourceInd)*400;
Ry = Ry(:,SourceInd)*400;
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

