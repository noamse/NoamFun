
EventNum = num2str(192630);
% Directory to save the catalogs. 
TargetPath = ['/home/noamse/KMT/data/AstCats/test/feb25d/kmt',EventNum, '/'];
%TargetPath = ['/home/noamse/KMT/data/AstCats/test/sites/kmt',EventNum, '/saao/'];
%TargetPath = ['/home/noamse/KMT/data/AstCats/test/kmt',EventNum, '/'];
mkdir(TargetPath);

%% Read 'CTIO_I' image files from all years 
Imagebasedir = ['/data2/KMTNetGUEST/events_highpriority/',EventNum ,'/*SAAO_I*/'];
[DirCell,JD]= ml.util.generateDirCell('BaseDir',Imagebasedir,'Site','SAAO');
refflag = contains(DirCell,'REF'); 
DirCell = DirCell(~refflag);
%FieldFlag = contains(DirCell,'BLG42'); 
%DirCell = DirCell(FieldFlag);
%% Generate a struct that contain all of the pipeline options
CCDSEC = [106,406,106,406];
Set= ImRed.setParameterStruct(TargetPath,'CCDSEC_xd',CCDSEC(1),'CCDSEC_xu',CCDSEC(2),'CCDSEC_yd',CCDSEC(3),'CCDSEC_yu',CCDSEC(4),...
    'MaxRefMag',18.5,'FitRadius',3.5,'NRefMagBin',12,'FitWings',true,'HalfSize',12,...
    'SNRforPSFConstruct',80,'InerRadiusKernel',2.5,'FitRadiusKernel',5,'ReCalcBack',false,'Dmin_thresh',3,'MaxRefMagPattern',16.5,...
    'fitPSFKernelModel','mtd');
Set.SaveFile = true;
% Generate KMTNet reference catalog for the specific field and cutouts
% The options file and the catalog will be written in TargetPath.
[RefCat,ImR] = ml.generateKMTRefCat(DirCell{50},Set,TargetPath,'Threshold',Set.SNRforPSFConstruct);
% ! Inspect the results, make sure the sources and the reference are
% aligned in ds9.
%ds9(ImR);ds9.plot([CCDSEC(1),CCDSEC(3)] + RefCat.getCol({'X','Y'})); 


%% Run the photometry pipeline on all images. 
% This step results is a directory 'TargetPath' with all of the catalogs.
 parfor Iep = 1:numel(DirCell)
     [PathIm] = ImRed.runPipe(DirCell{Iep},TargetPath);
     disp(Iep)
 end


%% Read catalogs 

[Obj,CelestialCoo,Matched]= ml.util.loadAstCatMatch(TargetPath);
% Remove bad airmass and false fit
FlagSeczAM = Obj.Data.secz(:,1)<1.6 ;
%flagMag = Obj.medianFieldSource({'MAG_PSF'})<17.5;
%Obj.Data=ml.util.flag_struct_field(Obj.Data,flagMag,'FlagByCol',true);
%Matched.Catalog = Matched.Catalog(flagMag,:); 
Obj.Data=ml.util.flag_struct_field(Obj.Data,FlagSeczAM,'FlagByCol',false);

Obj.JD = Obj.JD(FlagSeczAM);
FlagPix = Obj.Data.Yphase==-0.5|Obj.Data.Xphase==-0.5;
Obj.Data.X(FlagPix) = nan; Obj.Data.Y(FlagPix) = nan;
[IFsysB,MMSsysB]= ml.scripts.runIterDetrend(Obj.copy(),"CelestialCoo",CelestialCoo,'HALat',true,'UseWeights',true,'Plx',false,'PixPhase',true,'AnnualEffect',true,'NiterWeights',3,'NiterNoWeights',2,'ChromaicHighOrder',true);
[ObjSysAfter,sysCorX,sysCorY] = ml.detrend.sysRemScriptPart(IFsysB,MMSsysB,'UseWeight',true);
Xguess =median(ObjSysAfter.Data.X,'omitnan')'; Yguess =median(ObjSysAfter.Data.Y,'omitnan')';
% Flag sources with all nans, rare but can happend
FlagNan = ~(isnan(Xguess)|isnan(Yguess));
ObjSysAfter.Data = ml.util.flag_struct_field(ObjSysAfter.Data,FlagNan  ,'FlagByCol',true);
Matched.Catalog = Matched.Catalog(FlagNan,:);

[IFsys,MMSsys]= ml.scripts.runIterDetrend(ObjSysAfter,"CelestialCoo",CelestialCoo,'HALat',true,'UseWeights',true,'Plx',false,'PixPhase',true,'AnnualEffect',true,'NiterWeights',2,'NiterNoWeights',2,'ChromaicHighOrder',true);


%% Run first iteration and than SYSREM 
% IF = ml.scripts.runIterFit(Obj,"CelestialCoo",CelestialCoo,'NiterWeights',0,'NiterNoWeights',3,'HALat',false,'UseWeights',false,'Plx',false);
% [MMSObjSys,sysCorX,sysCorY] = ml.detrend.sysRemScriptPart(IF,Obj,'UseWeight',true);
% Xguess =median(MMSObjSys.Data.X,'omitnan')'; Yguess =median(MMSObjSys.Data.Y,'omitnan')';
% % Flag sources with all nans, rare but can happend
% FlagNan = ~(isnan(Xguess)|isnan(Yguess));
% ObjSys.Data = ml.util.flag_struct_field(MMSObjSys.Data,FlagNan  ,'FlagByCol',true);
% Matched.Catalog = Matched.Catalog(FlagNan,:);
% [IFobj,MMSobj]= ml.scripts.runIterDetrend(ObjSys,"CelestialCoo",CelestialCoo,'HALat',true,'UseWeights',true,'Plx',false,'PixPhase',true,'AnnualEffect',true,'NiterWeights',3,'NiterNoWeights',2,'ChromaicHighOrder',true);
% 
%% Run iterative solution for 
%[IFobj,MMSobj]= ml.scripts.runIterDetrend(ObjSys,"CelestialCoo",CelestialCoo,'HALat',true,'UseWeights',true,'Plx',false,'PixPhase',true,'AnnualEffect',true,'NiterWeights',3,'NiterNoWeights',2,'ChromaicHighOrder',true);


%%
close all;
%FLUX = IFobj.medianFieldSource({'FLUX_PSF'})
%H = [ones(size(FLUX)),-2.5*log10(FLUX)];
IFT = IFsys.copy();
load([TargetPath , 'RefCat.mat'])
M = IFT.medianFieldSource({'MAG_PSF'});
%zpfit = H(FLUX>0,:)\M(FLUX>0);
%zp= zpfit(1);

zp =28.469;
FluxRef = 10.^(0.4*(zp - RefCat.getCol('I')));
FluxMatch= 10.^(0.4*(zp - Matched.getCol('I')));
DistanceMatchedRef = pdist2(RefCat.getCol({'X','Y'}),Matched.getCol({'X','Y'}));
DistanceMatchedRef(DistanceMatchedRef==0)=Inf;
FluxDist = (FluxRef./FluxMatch')./DistanceMatchedRef.^2;
ContRatio = max(FluxDist)';
MinDistance = min(DistanceMatchedRef);
%FlagMagPlot = M<18.5;
% [RstdX,RstdY,M] = IFobj.plotResRMS;
[RstdX,RstdY] = IFT.calculateRstd;
 RstdBoot  = sqrt(RstdX.^2 +RstdY.^2);
scatter(M,RstdBoot,3000./(MinDistance'),log10(ContRatio ),'.')
set(gca,'ylim',[2,100]);
set(gca,'yscale','log');
yticks([5,10,20,50])
xticks([14,15,16,17,18,19])
ylabel('rms(Residuals) (2D) [mas]','Interpreter','latex')
xlabel('I [mag]','Interpreter','latex');
cb = colorbar;
caxis([min(log10(ContRatio)),prctile(log10(ContRatio ),80)]);
ylabel(cb,'$log(f_{\star}/f_{s}/d_{\star}^2)$','interpreter','latex','FontSize',17)
colormap('turbo');

figure; 
scatter(M,RstdY,3000./(MinDistance'),log10(ContRatio ),'.')
set(gca,'ylim',[2,100]);
set(gca,'yscale','log');
yticks([5,10,20,50])
xticks([14,15,16,17,18,19])
ylabel('rms(y-axis Residuals) (1D) [mas]','Interpreter','latex')
xlabel('I [mag]','Interpreter','latex');
cb = colorbar;
caxis([min(log10(ContRatio)),prctile(log10(ContRatio ),80)]);
ylabel(cb,'$log(f_{\star}/f_{s}/d_{\star}^2)$','interpreter','latex','FontSize',17)
colormap('turbo');

flagContRatio = ContRatio<0.1 & MinDistance'>4;

