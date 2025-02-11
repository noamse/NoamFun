function [ObjPix,PixCorrX,PixCorrY] = correctPixPhase(IF,ObjPix ,Args)
arguments
    IF; 
    ObjPix ; 
    Args.PixPhaseBinSize = 0.05; 
    Args.RstdTopPrc= 40;
    Args.PlotRes = false;
end


[ResX,ResY] =IF.calculateResiduals;
DataSt = IF.Data;

[RstdX,RstdY] = IF.calculateRstd;
FlagOut = isoutlier(ResX)|isoutlier(ResY);
ResY(FlagOut)=nan;ResX(FlagOut)=nan;
DataSt.ResY = ResY;DataSt.ResX = ResX;
Rstd  = sqrt(RstdX.^2 +RstdY.^2);
PrcTopRstd = prctile(Rstd,Args.RstdTopPrc);
Flag = Rstd < PrcTopRstd ; 
FlagHA = abs(DataSt.ha(:,1))<2;
DataSt = flag_struct_field(DataSt,Flag,'FlagByCol',true);
DataSt = flag_struct_field(DataSt,FlagHA ,'FlagByCol',false);



ParBinsSize=50;
ParBinStr  ='fwhm';
binCFlagCond = abs(DataSt.DeltaPSFXY(:))>0.4 & DataSt.C(:)<-9 & ~isnan(DataSt.ResX(:)) &~isnan(DataSt.Xphase(:));
%binCFlagCond =false(size(DataSt.C(:)));
%BxresC= timeSeries.bin.binningFast([IFsys.Data.C(1,:)', (1:numel(IFsys.Data.C(1,:)))'], ColorBinsSize,[NaN NaN],{'MidBin', @nanmean, @tools.math.stat.rstd,@numel});
[~,~,binC] = histcounts(DataSt.(ParBinStr)(:),'BinWidth',ParBinsSize);
binC(binCFlagCond )=0;
%binC(DataSt.C(:)<-9)=0;

binCunq= unique(binC(binC~=0));
XParPixelPhase = zeros(8,numel(binCunq));
YParPixelPhase = zeros(8,numel(binCunq));
%XParPixelPhase = zeros(3,numel(binCunq));
%YParPixelPhase = zeros(3,numel(binCunq));
for Ic = 1:numel(binCunq)
    FlagC = binC==binCunq(Ic);
    Bx = timeSeries.bin.binning([DataSt.Xphase(FlagC), DataSt.ResX(FlagC)], Args.PixPhaseBinSize,[NaN NaN],{'MidBin', @nanmean, ...
    @tools.math.stat.rstd,@numel,'StartBin','EndBin'});
    By = timeSeries.bin.binning([DataSt.Yphase(FlagC), DataSt.ResY(FlagC)], Args.PixPhaseBinSize,[NaN NaN],{'MidBin', @nanmean, ...
    @tools.math.stat.rstd,@numel,'StartBin','EndBin'});
    meanC = mean(DataSt.(ParBinStr)(FlagC),'omitnan');
    Hx = [ones(size(Bx(:,1))),Bx(:,1),Bx(:,1).^2,Bx(:,1).^3,Bx(:,1).^4,Bx(:,1).^5,Bx(:,1).^6,Bx(:,1).^7];
    Hy = [ones(size(By(:,1))),By(:,1),By(:,1).^2,By(:,1).^3,By(:,1).^4,By(:,1).^5,By(:,1).^6,By(:,1).^7];
    %Hpix = [ones(size(Bx(:,1))),Bx(:,1),Bx(:,1).^2,Bx(:,1).^3,Bx(:,1).^4,Bx(:,1).^5,Bx(:,1).^6,By(:,1),By(:,1).^2,By(:,1).^3,By(:,1).^4,By(:,1).^5,By(:,1).^6];
    %Hx = [ones(size(By(:,1))),sin(2*pi*Bx(:,1)),cos(2*pi*Bx(:,1))];
    %Hy = [ones(size(By(:,1))),sin(2*pi*By(:,1)),cos(2*pi*By(:,1))];
    XParPixelPhase(:,Ic) = lscov(Hx,Bx(:,2),Bx(:,4)./Bx(:,3).^2);
    YParPixelPhase(:,Ic) = lscov(Hy,By(:,2),By(:,4)./By(:,3).^2);


end



pixX = ObjPix.Data.Xphase(:);
pixY= ObjPix.Data.Yphase(:);
Hx = [ones(size(pixX)),pixX,pixX.^2,pixX.^3,pixX.^4,pixX.^5,pixX.^6,pixX.^7];
Hy = [ones(size(pixY)),pixY,pixY.^2,pixY.^3,pixY.^4,pixY.^5,pixY.^6,pixY.^7];
PixCorrX = Hx* XParPixelPhase;
PixCorrY = Hy* YParPixelPhase;
ObjPix.Data.X(:) = ObjPix.Data.X(:) - PixCorrX ;
ObjPix.Data.Y(:) = ObjPix.Data.Y(:) - PixCorrY;
if Args.PlotRes 
    figure;plot(pixX,Hx* XParPixelPhase*400,'.')
end
