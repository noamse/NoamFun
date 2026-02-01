function [CatsPath,IndSrc] = IterFitToPerSourceFormat(IFKris,CatsPath,Args)

arguments 
    IFKris
    CatsPath {mustBeNonzeroLengthText};
    Args.AddPMModel = true;
    Args.MaxMag = 18.5;
    Args.MinMag = 14;
end

%AddPMModel= true;
%/home/noamse/KMT/data/EVENTS/kmt170764/


%[RstdX,RstdY] = IFKris.plotResRMS;
[RstdX,RstdY] = IFKris.calculateRstd;
Rstd2D = sqrt(RstdX.^2 + RstdY.^2);
%flag = Rstd2D<30;
%flag = ContRatio<0.1 & MinDistance'>prctile(MinDistance',40);
M = IFKris.medianFieldSource({'MAG_PSF'});
%[OutLiersRMSvsMag]  =ml.util.iterativeOutlierDetection(Rstd2D,M,10,'MoveMedianStep',1);
[OutLiersRMSvsMag] = ml.util.detectOutliers_DualStage(Rstd2D,M,'Tightness',3);

IndEv = IFKris.findClosestSource([150,150]);
flag = ~OutLiersRMSvsMag & M<Args.MaxMag & M>Args.MinMag;
flag(IndEv)=true;
IndSrc = (1:IFKris.Nsrc)';

Wes = IFKris.calculateWes('NormalizeWeights',false);
[Rx,Ry] = IFKris.calculateResiduals;
Rx=Rx(:,flag); Ry=Ry(:,flag); IndSrc= IndSrc(flag);
SigmaAst = 400./sqrt(Wes(:,flag))/sqrt(2);
SigmaAst(~isfinite(SigmaAst)) = -1;
Mag = IFKris.Data.MAG_PSF(:,flag);
JD= IFKris.JD;
MagRMS = tools.math.stat.rstd(Mag);
SigmaPhot  = MagRMS .*ones(size(Mag));

Nsrc = numel(Rx(1,:));
if Args.AddPMModel
    ParS = IFKris.ParS(:,flag);
    ParS(1:2,:)=0;
    Rx = Rx+ IFKris.AsX*ParS;
    Ry = Ry+ IFKris.AsY*ParS;
    Rx = Rx - median(Rx,'omitnan');
    Ry = Ry - median(Ry,'omitnan');
    ColNames = {'JD','Rx','Ry','Mag','SigmaPhot','SigmaAst'};
else
    ColNames = {'JD','Rx','Ry','Mag','SigmaPhot','SigmaAst'};
end

Rx=Rx*400;
Ry=Ry*400;
mkdir(CatsPath);
for Isrc = 1:Nsrc
    T = array2table([JD,Rx(:,Isrc),Ry(:,Isrc),Mag(:,Isrc),SigmaPhot(:,Isrc),SigmaAst(:,Isrc)],'VariableNames',ColNames );
    
    writetable(T, [CatsPath,'Source_',num2str(IndSrc(Isrc)),'.csv']);
end

