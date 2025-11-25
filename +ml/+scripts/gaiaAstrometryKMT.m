function [ParScalibrated,T,DeltaPM_KMT_GAIA,OutLiersRMSvsMag,PMRA_kmt_to_gaia_fit,PMDec_kmt_to_gaia_fit] = gaiaAstrometryKMT(IF,Matched,Args)
arguments
    IF;
    Matched = AstroCatalog;
    %EventNumStr = num2str(192630);
    Args.GaiaCatMatchedFile= [];
    Args.RstdTopPrc = 33;
    Args.MaxMag = 18;
    Args.MinPos = 12;
end




% !!!!! WORKS WITH catsHTM !!!!!
% Cross match Gaia-KMT catalogs. 
[KMTGAIACat, SelObj, ResInd, CatH] =imProc.match.match_catsHTM(Matched.copy(),'GAIADR3','Radius',0.05);

Tgaia = CatH.Table(ResInd.Obj1_FlagNearest,:);
[~,Isort] = sort(ResInd.Obj1_IndInObj2(ResInd.Obj1_FlagNearest));
Tgaia = Tgaia(Isort,:);
% 
Tgaia = renamevars(Tgaia,{'PMRA','PMDec','ErrPMRA','ErrPMDec'}, {'pmra','pmdec','pmra_error','pmdec_error'});
KMTTab = SelObj.Table;
KMTTab = removevars(KMTTab , {'RA', 'Dec'});
T = [Tgaia,KMTTab];
idxKMT = ~isnan(ResInd.Obj2_IndInObj1);
% Subset Gaia table and align both catalogs
%T = T(idxGaia, :);                                % Gaia subset for matched sources
 Pars = IF.ParS(:, idxKMT);                   % Parameters of matched KMT sources
% ls 
% Filter accompanying vectors
[RstdX,RstdY] = IF.calculateRstd;
RstD = sqrt(RstdX.^2 + RstdY.^2);

MagPSF = IF.medianFieldSource({'MAG_PSF'});
MagPSF = MagPSF(idxKMT);
I= Matched.getCol('I');
I = I(idxKMT);
RstDIdx = RstD(idxKMT);
%RstDplotY = RstdY(idxKMT);
%RstDplotX = RstdX(idxKMT);
OutLiersRMSvsMag = ml.util.iterativeOutlierDetection(RstDIdx,MagPSF,10,'MoveMedianStep',1);

H = [ones(size(T.phot_rp_mean_mag)),T.phot_rp_mean_mag];
FlagMagComp = ~isnan(T.phot_rp_mean_mag);
MagCompPar = H(FlagMagComp,:)\MagPSF(FlagMagComp);
FlagOutMagComp = ~(isoutlier(H* MagCompPar- MagPSF));

XY = IF.medianFieldSource({'X','Y'});
TopPrcVal= prctile(RstD ,Args.RstdTopPrc);

FlagForFitTran= T.I<Args.MaxMag&RstDIdx <TopPrcVal&FlagOutMagComp & ~OutLiersRMSvsMag & abs(I-MagPSF)<0.5 ;

DeltaPMRA= Pars(3,FlagForFitTran)'.*400+ T.pmra(FlagForFitTran);
DeltaPMRA = DeltaPMRA - -median(DeltaPMRA);
ErrDeltaPMRA = T.pmra_error(FlagForFitTran );

DeltaPMDec = Pars(4,FlagForFitTran)'.*400- T.pmdec(FlagForFitTran);
DeltaPMDec = DeltaPMDec  -median(DeltaPMDec );
ErrDeltaPMDec = T.pmdec_error(FlagForFitTran );
FlagIsOut = ~(isoutlier(DeltaPMRA,2)|isoutlier(DeltaPMDec,2));
FlagForFitTran(FlagForFitTran) = FlagIsOut ;

Hrob = [Pars(1,:)',Pars(2,:)',Pars(3,:)',Pars(4,:)'];
Hra = [ones(size(Hrob(:,1))),Hrob];
Hdec = [ones(size(Hrob(:,1))),Hrob];
PMRA_kmt_to_gaia_fit= robustfit(Hrob(FlagForFitTran,:) ,T.pmra(FlagForFitTran));
PMDec_kmt_to_gaia_fit= robustfit(Hrob(FlagForFitTran,:) ,T.pmdec(FlagForFitTran));

Delta_T = (IF.JD0 - 2457389.0)./365.25;
GaiaRA = T.RA ;%+ Delta_T*T.pmra/1000/3600/180*pi;
GaiaDec = T.Dec ;%+ Delta_T*T.pmdec/1000/3600/180*pi;

KMTPMRACal = [ones(size(Hrob(:,1))),Hrob]*PMRA_kmt_to_gaia_fit;
KMTPMDecCal = [ones(size(Hrob(:,1))),Hrob]*PMDec_kmt_to_gaia_fit;
Hpos = [Pars(1,:)',Pars(2,:)',KMTPMRACal,KMTPMDecCal];
%Hpos = Hrob;
RA_kmt_to_gaia_fit= robustfit(Hpos(FlagForFitTran,:) ,GaiaRA(FlagForFitTran));
Dec_kmt_to_gaia_fit= robustfit(Hpos(FlagForFitTran,:) ,GaiaDec(FlagForFitTran)');
disp(tools.math.stat.rstd(([ones(size(Hpos(FlagForFitTran,1))),Hpos(FlagForFitTran,:)]*Dec_kmt_to_gaia_fit- GaiaDec(FlagForFitTran))*3600*1000*180/pi))
disp(tools.math.stat.rstd(([ones(size(Hpos(FlagForFitTran,1))),Hpos(FlagForFitTran,:)]*RA_kmt_to_gaia_fit- GaiaRA(FlagForFitTran))*3600*1000*180/pi*cos(T.Dec(1))));

Hall = [ones(size(IF.ParS(1,:)')),IF.ParS(1,:)',IF.ParS(2,:)',IF.ParS(3,:)',IF.ParS(4,:)'];
PMRACalibrated = Hall*PMRA_kmt_to_gaia_fit;
PMDecCalibrated = Hall*PMDec_kmt_to_gaia_fit;
Hallpos = [ones(size(IF.ParS(1,:)')),IF.ParS(1,:)',IF.ParS(2,:)',PMRACalibrated,PMDecCalibrated];

RACalibrated = Hallpos*RA_kmt_to_gaia_fit;
DecCalibrated = Hallpos*Dec_kmt_to_gaia_fit;

ParScalibrated = [RACalibrated,DecCalibrated,PMRACalibrated,PMDecCalibrated];
%ParScalibrated = [PMRACalibrated,PMDecCalibrated];
HorbL = [ones(size(Hrob(:,1))),Hrob];
PMRA_KMT = HorbL*PMRA_kmt_to_gaia_fit;
PMDec_KMT = HorbL*PMDec_kmt_to_gaia_fit;

DeltaPM_KMT_GAIA = [PMRA_KMT-T.pmra,PMDec_KMT-T.pmdec];
DeltaPos_KMT_GAIA = [];

end