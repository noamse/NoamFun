function [RefCat,Im]= generateKMTRefCat(ImPath,Set,TargetPath,Args)
arguments
    ImPath
    Set
    TargetPath
    Args.Threshold = 150;
    Args.MedianCubeSumRange = [0.8 4];
    Args.ColNumMagRefTab = 3;
    Args.Range = [-100,100];
    Args.Step = 0.05
    Args.MaxRefMagPattern = [];
    Args.ColName9K = {'X','Y','I','V-I','Var','??','RA','Dec','Patch1','Patch2','XpatchPos','YpatchPos'} ;
    Args.SaveCat= true;
    Args.HistoryKey  = 'HISTORY';
end

RefTab = ml.kmt.read_kmt9k_cat(ImPath,'MaxMag',Set.MaxRefMag,'HistoryKey',Args.HistoryKey );
Im = AstroImage(ImPath );
Im.Image=single(Im.Image);
Im = imProc.sources.findMeasureSources(Im,'Threshold',Args.Threshold,'RemoveBadSources',true,'BackPar',...
    {'BackFun',@median,'BackFunPar',{'all','omitnan'},'VarFun','@imUtil.background.rvar'});
%[Im] =imProc.psf.constructPSF(Im,'constructPSF_cutoutsArgs',{'MedianCubeSumRange',[0.8 4]});
%[Im] =imProc.sources.psfFitPhot(Im,'psfPhotCubeArgs',{'UseSourceNoise',false});
%[Im] =ml.pipe.psfFitPhot(Im,'psfPhotCubeArgs',{'UseSourceNoise',false});

Isort = (sort(RefTab(:,Args.ColNumMagRefTab)));
MaxI = Isort(round(numel(Im.CatData.Catalog(:,1))));

[NewX,NewY,PatternMat]= ml.kmt.match_kmt9k_Pattern(Im.CatData,RefTab,'Range',Args.Range,'MaxMag',MaxI,'XYCols',{'X','Y'},'Step',Args.Step);
RefCatNew = RefTab;
RefCatNew(:,[1,2]) =[NewX,NewY];

% Check chromatics 


%ColName = {'DB_no','X','Y','Xchip','Ychip','I','V-I','Var','??','RA','Dec','Patch1','Patch2','XpatchPos','YpatchPos'} ;
%ColName9K = {'X','Y','I','V-I','Var','??','RA','Dec','Patch1','Patch2','XpatchPos','YpatchPos'} ;
RefCat = AstroCatalog({RefCatNew},'ColNames',Args.ColName9K);
%flagChromatic= RefCat.getCol('V-I')<1.8 & RefCat.getCol('V-I')>1;
%RefCat.Catalog = RefCat.Catalog(flagChromatic,:);

%save([TargetPath , 'RefCat.mat'],'RefCat');
%Set= ImRed.setParameterStruct(TargetPath,'CCDSEC_xd',412,'CCDSEC_xu',612,'CCDSEC_yd',412,'CCDSEC_yu',612);
RefCat= ml.pipe.util.setOgleCat(TargetPath,'OgleCat',RefCat,'SavedCatFileName','RefCat.mat','SaveCat',Args.SaveCat);



