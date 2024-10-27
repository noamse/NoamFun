function Cat    = iterativePSFPhot(self,Im,Args) % tbd

arguments
    self;
    Im;
    Args.ColNameX   = 'X';
    Args.ColNameY   = 'Y';
    Args.FitRadius  = 3;
    Args.NRefMagBin = 5;
    Args.ColNameMag = 'I';
    Args.UseSourceNoise = true;
    Args.ReCalcBack = false;
    Args.RecenterPSF= true;
    Args.HalfSize   = 10;
    
end

Im.CatData = AstroCatalog;
try
    RefXY = self.RefCatalog.getCol({Args.ColNameX,Args.ColNameY});
    
    [Cat,~,~]=  ml.pipe.imProc.psfFitPhotIter(Im.copy(),'XY',RefXY,'PSF',Im.PSF...
    ,'MAG',self.RefCatalog.getCol(Args.ColNameMag),'NRefMagBin',Args.NRefMagBin,'FitRadius',Args.FitRadius,...
    'HalfSize',Args.HalfSize,'UseSourceNoise',Args.UseSourceNoise,...
    'RecenterPSF',Args.RecenterPSF,'ReCalcBack',Args.ReCalcBack);
    
catch
   Cat = AstroCatalog;
   disp('Failed to run psf photometry')
end




end