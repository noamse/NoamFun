function [ImagePath] = runPipeSim(ImagePath,CatPathTarget)

IR = ImRed(ImagePath,CatPathTarget);
IR.Set  = readParameterStruct(IR);

Im      = loadImage(IR); % done
IR.RefCatalog  = loadRefCat(IR);
HalfSize = IR.Set.HalfSize;
try
    
    %Im      = constructPSF(IR,Im,'HalfSize',HalfSize,'findMeasureSourcesArgs',{'Threshold',10,'PsfFunPar',{[0.5; 1.0; 1;]},...
    %   'RemoveBadSources',true,'ReCalcBack',true,'BackPar',{'BackFunPar',{'MinVal',600},'VarFun',@imUtil.background.rvar}}); % Need to add the selectPsfStars parameters to Set
    Im      = constructPSF(IR,Im,'HalfSize',HalfSize,'findMeasureSourcesArgs',{'Threshold',10,'PsfFunPar',{[0.5; 1.0; 1;]},...
'RemoveBadSources',true,'ReCalcBack',true,'BackPar',{'VarFun',@imUtil.background.rvar}});

    if isempty(Im.PSF)
        error('Empty PSF/Catalog');
    end
catch
    disp('Failed to construct PSF')
    Cat = AstroCatalog;
    IR.populateMetaData(Cat,Im);
    saveOutputCat(IR,Cat)
    return
end

IR.RefCatalog  = adjustRefCat(IR,Im); % tbd
if Im.HeaderData.isKeyExist('EQUINOX')
    Im.HeaderData.replaceVal({'EQUINOX'},{2000});
end
% if IR.RefCatalog.isemptyCatalog
%     Cat=AstroCatalog;
%     IR.populateMetaData(Cat,Im);
%     saveOutputCat(IR,Cat);
%     return;
% end

try

RefCat = IR.RefCatalog.copy();
Im = imProc.sources.findMeasureSources(Im.copy(),'OnlyForced',true,'ForcedList',RefCat.getCol({'X','Y'}));
%[Im] =imProc.psf.constructPSF(Im,'constructPSF_cutoutsArgs',{'SmoothWings',false,...
  %  'psf_zeroConvergeArgs',{'Radius',IR.Set.HalfSize}},'HalfSize',IR.Set.HalfSize);
catch 
    disp('Failed to construct PSF in second iter')
    Cat = AstroCatalog;
    IR.populateMetaData(Cat,Im);
    saveOutputCat(IR,Cat)
    return;
end
if IR.Set.UseKernelPSFPhotometry
    Im      = populatePSFKernel(IR,Im); % done
end


%FitRadius = Im.PSFData.fwhm*0.9;

Cat    = iterativePSFPhot(IR,Im,'HalfSize',HalfSize,'FitRadius',IR.Set.FitRadius,'NRefMagBin',IR.Set.NRefMagBin,...
    'UseSourceNoise',IR.Set.UseSourceNoise,'ReCalcBack',IR.Set.ReCalcBack);
%Cat    = iterativePSFPhot(IR,Im,'HalfSize',HalfSize,'FitRadius',FitRadius,'NRefMagBin',IR.Set.NRefMagBin);
%IR.populateMetaData(Cat,Im);
Cat.JD = Im.HeaderData.getVal('JD');
saveOutputCat(IR,Cat)
%ImagePath
end