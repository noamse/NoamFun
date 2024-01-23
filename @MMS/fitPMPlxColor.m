function [Pars,ParsErr]   = fitPMPlxColor(Obj,Color,Args)

arguments
    Obj;
    Color;
    Args.MaxMag = 19; 
    Args.Coo=[];
    Args.MoveWindowSize = 100;
    Args.C0 = 0;
    
    
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


    
Cbar = Color-Args.C0;
Hpm = designMatrixPM(Obj);
Hzero= zeros(size(Hpm));
Pars=  zeros(7,Obj.Nsrc);
PA= Obj.getTimeSeriesField(1,{'pa'});
ParsErr = zeros(size(Pars));
for Isrc = 1:Obj.Nsrc
    XYSrc= Obj.getTimeSeriesField(Isrc,{'X','Y'});
    %Paralactic= Obj.getTimeSeriesField(Isrc,{'pa'});
    RAPlxTerm= -1/400*(X.*sin(RA(Isrc))- Y.*cos(RA(Isrc))); 
    DecPlxTerm= 1/400*(X.*cos(RA(Isrc)).*sin(RA(Isrc)) + Y.*sin(RA(Isrc)).*sin(Dec(Isrc)) - Z.*cos(Dec(Isrc))) ; 
    
    ColorTermSin = 1/400*Cbar(Isrc).*sin(PA);
    ColorTermCos = 1/400*Cbar(Isrc).*cos(PA);
    
    Outx = isoutlier(XYSrc(:,1),'movmean',Args.MoveWindowSize);
    Outy = isoutlier(XYSrc(:,2),'movmean',Args.MoveWindowSize);
    
    Out = Outx | Outy;
    
    
    Flag = ~any(isnan(XYSrc),2) & ~Out & ~isnan(PA);
    %Flag = [Flag;Flag];
    Bx = timeSeries.bin.binningFast([Hpm(Flag,2), XYSrc(Flag,1)], Args.TimeBinSize,[NaN NaN],{'MidBin', @nanmean, @tools.math.stat.rstd,@numel});
    By = timeSeries.bin.binningFast([Hpm(Flag,2), XYSrc(Flag,2)], Args.TimeBinSize,[NaN NaN],{'MidBin', @nanmean, @tools.math.stat.rstd,@numel});
    Bx(Bx(:,3)==0)=max(Bx(:,3));
    By(By(:,3)==0)=max(By(:,3));
    FlagBin = Bx(:,4)> 2 & By(:,4)>2;
    Bx= Bx(FlagBin,:);
    By= By(FlagBin,:);

    HpmSrc = Obj.designMatrixPM('JD',Bx(:,1),'JD0',0);
    Hzero = zeros(size(HpmSrc));
    [H]  = designMatPMPlxColor(Obj,Cbar(Isrc),[RA(Isrc),Dec(Isrc)]);
    RAPlxTermInterp = interp1(Hpm(:,2),RAPlxTerm,Bx(:,1));
    DecPlxTermInterp = interp1(Hpm(:,2),DecPlxTerm,Bx(:,1));
    H = [HpmSrc,Hzero,RAPlxTermInterp;Hzero,HpmSrc,DecPlxTermInterp];
    
    H = [Hpm,Hzero,RAPlxTerm,ColorTermSin,ColorTermCos;Hzero,Hpm,DecPlxTerm,ColorTermSin,ColorTermCos];
    
    Yfit = [XYSrc(:,1);XYSrc(:,2)];   
    [Pars(:,Isrc),~] = lscov(H(Flag,:),Yfit(Flag));
    %[Pars(:,Isrc),ParsErr(:,Isrc)] = lscov(H(Flag,:),Yfit(Flag));
    
end
