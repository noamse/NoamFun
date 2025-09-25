function [CatsPath,IFsys,Obj,Matched]=runOverFields(EventNum,Args)

arguments
    EventNum ;
    Args.processKMTEventsArgs = {};
    Args.RunReduction =false;
    Args.PerSourcesTargetPath = '/home/noamse/KMT/data/EVENTS/';
    Args.TargetBasePath = '/home/noamse/KMT/data/Results/';
    Args.TargetPath = '';
    Args.Site = 'CTIO';
end

% if Args.RunReduction
%     ml.kmt.processKMTEvent(EventNum, Args.processKMTEventsArgs{:});
% end
if isempty(Args.TargetPath)
    AstCatsDirPath = [Args.TargetBasePath,'kmt',num2str(EventNum),'/',Args.Site,'/'];
else
    AstCatsDirPath = Args.TargetPath;
end
try 
    [Obj, CelestialCoo, Matched] = ml.scripts.readCatsPath(AstCatsDirPath );
catch ME
    fprintf('Error: %s\n', ME.message);
    fprintf('Failed to load Catalogs');
    CatsPath='';IFsys=[];Obj=[];Matched=AstroCatalog;
    return
end




[IFsysB,MMSsysB]= ml.scripts.runIterDetrend(Obj.copy(),"CelestialCoo",CelestialCoo,'HALat',true,'UseWeights',true,'PixPhase',false,'AnnualEffect',true,'NiterWeights',10,'NiterNoWeights',2);
% sysrem 
[ObjSysAfter,sysCorX,sysCorY] = ml.util.sysRemScriptPart(IFsysB,MMSsysB,'UseWeight',true,'NIter',2);
Xguess =median(ObjSysAfter.Data.X,'omitnan')'; Yguess =median(ObjSysAfter.Data.Y,'omitnan')';
% Flag sources with all nans, rare but can happend
FlagNan = ~(isnan(Xguess)|isnan(Yguess));
ObjSysAfter.Data = ml.util.flag_struct_field(ObjSysAfter.Data,FlagNan  ,'FlagByCol',true);
Matched.Catalog = Matched.Catalog(FlagNan,:);
% Final run
[IFsys,~]= ml.scripts.runIterDetrend(ObjSysAfter,'IF',IFsysB.copy(),"CelestialCoo",CelestialCoo,'HALat',true,'UseWeights',true,'PixPhase',false,'AnnualEffect',true,'NiterWeights',4,'NiterNoWeights',2,'FinalStep',true);


PathToTables = [Args.PerSourcesTargetPath,'kmt',num2str(EventNum),'/'];
CatsPath = ml.scripts.IterFitToPerSourceFormat(IFsys,PathToTables);