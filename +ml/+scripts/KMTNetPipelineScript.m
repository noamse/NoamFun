
EventNum = num2str(192630);
% Directory to save the catalogs. 
TargetPath = ['/home/noamse/KMT/data/AstCats/test/feb25d/kmt',EventNum, '/'];
%TargetPath = ['/home/noamse/KMT/data/AstCats/test/kmt',EventNum, '/'];
mkdir(TargetPath);

%% Read 'CTIO_I' image files from all years 
Imagebasedir = ['/data2/KMTNetGUEST/events_highpriority/',EventNum ,'/*CTIO_I*/'];
[DirCell,JD]= ml.util.generateDirCell('BaseDir',Imagebasedir);
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
[RefCat,ImR] = ml.generateKMTRefCat(DirCell{15},Set,TargetPath,'Threshold',Set.SNRforPSFConstruct);
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


%% Run first iteration and than SYSREM 
IF = ml.scripts.runIterFit(Obj,"CelestialCoo",CelestialCoo,'NiterWeights',0,'NiterNoWeights',3,'HALat',false,'UseWeights',false,'Plx',false);
[ObjSys,sysCorX,sysCorY] = ml.detrend.sysRemScriptPart(IF,Obj,'UseWeight',true);
Xguess =median(ObjSys.Data.X,'omitnan')'; Yguess =median(ObjSys.Data.Y,'omitnan')';
% Flag sources with all nans, rare but can happend
FlagNan = ~(isnan(Xguess)|isnan(Yguess));
ObjSys.Data = ml.util.flag_struct_field(ObjSys.Data,FlagNan  ,'FlagByCol',true);
Matched.Catalog = Matched.Catalog(FlagNan,:);
%% Run iterative solution for 
[IFobj,MMSobj]= ml.scripts.runIterDetrend(ObjSys,"CelestialCoo",CelestialCoo,'HALat',true,'UseWeights',true,'Plx',false,'PixPhase',true,'AnnualEffect',true,'NiterWeights',3,'NiterNoWeights',2,'ChromaicHighOrder',true);
%[IFobjPlx,MMSobjPlx]= ml.scripts.runIterDetrend(ObjSys,"CelestialCoo",CelestialCoo,'HALat',true,'UseWeights',true,'Plx',true,'PixPhase',true,'AnnualEffect',false,'NiterWeights',10,'NiterNoWeights',3,'ChromaicHighOrder',true);


