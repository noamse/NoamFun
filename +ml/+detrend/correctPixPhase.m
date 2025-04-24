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
M = IF.medianFieldSource({'MAG_PSF'});
OutLiersFlagOriginal = ml.util.iterativeOutlierDetection(Rstd,M,10,'MoveMedianStep',0.5);
Flag = Rstd < PrcTopRstd &~OutLiersFlagOriginal; 
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
    Bxx = timeSeries.bin.binning([DataSt.Xphase(FlagC), DataSt.ResX(FlagC)], Args.PixPhaseBinSize,[NaN NaN],{'MidBin', @nanmedian, ...
    @tools.math.stat.rstd,@numel,'StartBin','EndBin'});
    Bxy = timeSeries.bin.binning([DataSt.Xphase(FlagC), DataSt.ResY(FlagC)], Args.PixPhaseBinSize,[NaN NaN],{'MidBin', @nanmedian, ...
    @tools.math.stat.rstd,@numel,'StartBin','EndBin'});
    Byy = timeSeries.bin.binning([DataSt.Yphase(FlagC), DataSt.ResY(FlagC)], Args.PixPhaseBinSize,[NaN NaN],{'MidBin', @nanmedian, ...
    @tools.math.stat.rstd,@numel,'StartBin','EndBin'});
    Byx = timeSeries.bin.binning([DataSt.Yphase(FlagC), DataSt.ResX(FlagC)], Args.PixPhaseBinSize,[NaN NaN],{'MidBin', @nanmedian, ...
    @tools.math.stat.rstd,@numel,'StartBin','EndBin'});
    meanC = mean(DataSt.(ParBinStr)(FlagC),'omitnan');
    %Hx = [ones(size(Bxx(:,1))),Bxx(:,1),Bxx(:,1).^2,Bxx(:,1).^3,Bxx(:,1).^4,Bxx(:,1).^5,Bxx(:,1).^6,Bxx(:,1).^7];
    %Hy = [ones(size(Byy(:,1))),Byy(:,1),Byy(:,1).^2,Byy(:,1).^3,Byy(:,1).^4,Byy(:,1).^5,Byy(:,1).^6,Byy(:,1).^7];
    Hxx = [ones(size(Bxx(:,1))),Bxx(:,1),Bxx(:,1).^2,Bxx(:,1).^3,Bxx(:,1).^4,Bxx(:,1).^5,Bxx(:,1).^6,Bxx(:,1).^7];
    Hy = [ones(size(Byy(:,1))),Byy(:,1),Byy(:,1).^2,Byy(:,1).^3,Byy(:,1).^4,Byy(:,1).^5,Byy(:,1).^6,Byy(:,1).^7];
    %Hpix = [ones(size(Bxx(:,1))),Bxx(:,1),Bxx(:,1).^2,Bxx(:,1).^3,Bxx(:,1).^4,Bxx(:,1).^5,Bxx(:,1).^6,Byy(:,1),Byy(:,1).^2,Byy(:,1).^3,Byy(:,1).^4,Byy(:,1).^5,Byy(:,1).^6];
    %Hx = [ones(size(Byy(:,1))),sin(2*pi*Bxx(:,1)),cos(2*pi*Bxx(:,1))];
    %Hy = [ones(size(Byy(:,1))),sin(2*pi*Byy(:,1)),cos(2*pi*Byy(:,1))];
    XParPixelPhase(:,Ic) = lscov(Hxx,Bxx(:,2),Bxx(:,4)./Bxx(:,3).^2);
    YParPixelPhase(:,Ic) = lscov(Hy,Byy(:,2),Byy(:,4)./Byy(:,3).^2);


end



pixX = ObjPix.Data.Xphase(:);
pixY= ObjPix.Data.Yphase(:);
%Hxx = [ones(size(pixX)),pixX,pixX.^2,pixX.^3,pixX.^4,pixX.^5,pixX.^6,pixX.^7];
Hxx = [ones(size(pixX)),pixX,pixX.^2,pixX.^3,pixX.^4,pixX.^5,pixX.^6,pixX.^7];
Hy = [ones(size(pixY)),pixY,pixY.^2,pixY.^3,pixY.^4,pixY.^5,pixY.^6,pixY.^7];
PixCorrX = Hxx* XParPixelPhase;
PixCorrY = Hy* YParPixelPhase;
ObjPix.Data.X(:) = ObjPix.Data.X(:) - PixCorrX ;
ObjPix.Data.Y(:) = ObjPix.Data.Y(:) - PixCorrY;
if Args.PlotRes 
    figure;plot(pixX,Hxx* XParPixelPhase*400,'.')
end
