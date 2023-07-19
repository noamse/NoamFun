function [ImagePath] = runPipe(ImagePath,CatPathTarget)

IR = ImRed(ImagePath,CatPathTarget);
IR.Set  = setParameterStruct(IR);

Im      = loadImage(IR); % done
IR.RefCatalog  = loadRefCat(IR);

Im      = constructPSF(IR,Im); % Need to add the selectPsfStars parameters to Set
Im      = populatePSFKernel(IR,Im); % done
IR.RefCatalog  = adjustRefCat(IR,Im); % tbd
Cat    = iterativePSFPhot(IR,Im);
IR.populateMetaData(Cat,Im);
saveOutputCat(IR,Cat)
%ImagePath
end