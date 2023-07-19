function runPSFPhotometryForced(self,Args)
arguments 
    self; 
    Args;
end



Im = AstroImage(self.ImagePath,'CCDSEC',[Args.CCDSEC_xd,Args.CCDSEC_xu,Args.CCDSEC_yd,Args.CCDSEC_yu]   );
Im.Image = single(Im.Image);




[Cat] = ml.pipe.mextractorIterRefcat(Im,Args.OgleCat.copy(),'FitRadius',Args.FitRadius,'HalfSize'...
    ,Args.HalfSize,'PSFfitConvThresh',Args.PSFfitConvThresh,'PSFfitmaxStep',Args.PSFfitmaxStep,'PSFfitMaxIter',Args.PSFfitMaxIter...
    ,'SNRforPSFConstruct',Args.SNRforPSFConstruct...
    ,'NRefMagBin',Args.NRefMagBin,'FitWings',Args.FitWings...
    ,'fitPSFKernelModel',Args.fitPSFKernelModel,'FitRadiusKernel',Args.FitRadiusKernel,'PSFSmallStep',Args.PSFSmallStep,...
    'UseKernelPSFPhotometry',Args.UseKernelPSFPhotometry,'ImagClip',Args.MaxRefMagForPattern);





