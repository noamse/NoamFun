function [Pars,ParsErr]   = fitProperMotionPlx(Obj,Args)

arguments
    Obj;
    Args.MaxMag = 19; 
    Args.Coo=[];
    Args.TimeBinSize = 15;
    Args.MoveWindowSize = 50;
end






[Ecoo] = celestial.SolarSys.calc_vsop87(Obj.JD, 'Earth', 'e', 'E');



X = Ecoo(1,:)'; Y = Ecoo(2,:)'; Z = Ecoo(3,:)';

%RAPlxTerm= (X.*sin(RA)- Y.*cos(RA)); 
%DecPlxTerm= X.*cos(RA).*sin(RA) + Y.*sin(RA).*sin(Dec) - Z.*cos(Dec) ; 
%Note that \hat{RA} = -\hat{X} for KMTNet telescope.

if isempty(Args.Coo)
    RA = Obj.medianFieldSource({'RA'});
    Dec = Obj.medianFieldSource({'Dec'});
else
    RA = Args.Coo(:,1);
    Dec = Args.Coo(:,2);
end

Hpm = designMatrixPM(Obj);
Hzero= zeros(size(Hpm));
Pars=  zeros(5,Obj.Nsrc);
ParsErr = zeros(5,Obj.Nsrc);
for Isrc = 1:Obj.Nsrc
    XYSrc= Obj.getTimeSeriesField(Isrc,{'X','Y'});
    RAPlxTerm= -1/400*(X.*sin(RA(Isrc))- Y.*cos(RA(Isrc))); 
    DecPlxTerm= 1/400*(X.*cos(RA(Isrc)).*sin(RA(Isrc)) + Y.*sin(RA(Isrc)).*sin(Dec(Isrc)) - Z.*cos(Dec(Isrc))) ; 
    
    
    
    Outx = isoutlier(XYSrc(:,1),'movmean',Args.MoveWindowSize);
    Outy = isoutlier(XYSrc(:,2),'movmean',Args.MoveWindowSize);
    
    
    
    Out = Outx | Outy;
    
    

    

    
    
    Flag = ~any(isnan(XYSrc),2) & ~Out;
    Bx = timeSeries.bin.binningFast([Hpm(Flag,2), XYSrc(Flag,1)], Args.TimeBinSize,[NaN NaN],{'MidBin', @nanmean, @tools.math.stat.rstd,@numel});
    By = timeSeries.bin.binningFast([Hpm(Flag,2), XYSrc(Flag,2)], Args.TimeBinSize,[NaN NaN],{'MidBin', @nanmean, @tools.math.stat.rstd,@numel});
    Bx(Bx(:,3)==0)=max(Bx(:,3));
    By(By(:,3)==0)=max(By(:,3));
    FlagBin = Bx(:,4)> 2 & By(:,4)>2;
    Bx= Bx(FlagBin,:);
    By= By(FlagBin,:);
    
    HpmSrc = Obj.designMatrixPM('JD',Bx(:,1),'JD0',0);
    Hzero = zeros(size(HpmSrc));
    RAPlxTermInterp = interp1(Hpm(:,2),RAPlxTerm,Bx(:,1));
    DecPlxTermInterp = interp1(Hpm(:,2),DecPlxTerm,Bx(:,1));
    H = [HpmSrc,Hzero,RAPlxTermInterp;Hzero,HpmSrc,DecPlxTermInterp];
    Yfit = [Bx(:,2);By(:,2)];    
    Sigma = 1./([Bx(:,3)./sqrt(Bx(:,4));By(:,3)./sqrt(By(:,4))]);    
    ParsFirstIter = lscov(H,Yfit,Sigma);
    
    %Clip after first iteration
    PosModel = H*ParsFirstIter;
    XPosModel = PosModel(1:numel(PosModel)/2);
    YPosModel = PosModel(numel(PosModel)/2+1:end);
    [~ ,OutlierIter1X] = rmoutliers(XPosModel - Bx(:,2));
    [~ ,OutlierIter1Y] = rmoutliers(YPosModel - By(:,2));
    Clip = OutlierIter1X | OutlierIter1Y;
    FlagClip = [~Clip;~Clip];
    [Pars(:,Isrc),ParsErr(:,Isrc)] = lscov(H(FlagClip,:),Yfit(FlagClip),Sigma(FlagClip));
    
    %[Pars(:,Isrc),ParsErr(:,Isrc)] = lscov(H,Yfit,Sigma);
    %Flag = [Flag;Flag];
    %H = [Hpm,Hzero,RAPlxTerm;Hzero,Hpm,DecPlxTerm];
    %Yfit = [XYSrc(:,1);XYSrc(:,2)];    
    %[Pars(:,Isrc),ParsErr(:,Isrc)] = lscov(H(Flag,:),Yfit(Flag));
    
end

