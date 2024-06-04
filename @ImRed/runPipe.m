function [ImagePath] = runPipe(ImagePath,CatPathTarget)

IR = ImRed(ImagePath,CatPathTarget);
IR.Set  = readParameterStruct(IR);

Im      = loadImage(IR); % done
IR.RefCatalog  = loadRefCat(IR);
HalfSize = IR.Set.HalfSize;
try
    
    Im      = constructPSF(IR,Im,'HalfSize',HalfSize,'findMeasureSourcesArgs',{'Threshold',50,'PsfFunPar',{[0.5; 1.0; 1;]},...
       'RemoveBadSources',true,'ReCalcBack',true}); % Need to add the selectPsfStars parameters to Set

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
if IR.Set.UseKernelPSFPhotometry
    Im      = populatePSFKernel(IR,Im); % done
end
IR.RefCatalog  = adjustRefCat(IR,Im); % tbd
if Im.HeaderData.isKeyExist('EQUINOX')
    Im.HeaderData.replaceVal({'EQUINOX'},{2000});
end

%FitRadius = Im.PSFData.fwhm*0.9;

Cat    = iterativePSFPhot(IR,Im,'HalfSize',HalfSize,'FitRadius',IR.Set.FitRadius,'NRefMagBin',IR.Set.NRefMagBin,...
    'UseSourceNoise',IR.Set.UseSourceNoise,'ReCalcBack',IR.Set.ReCalcBack);
%Cat    = iterativePSFPhot(IR,Im,'HalfSize',HalfSize,'FitRadius',FitRadius,'NRefMagBin',IR.Set.NRefMagBin);
IR.populateMetaData(Cat,Im);
saveOutputCat(IR,Cat)
%ImagePath
end