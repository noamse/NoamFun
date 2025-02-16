function [Im,BestFitPar]   = populatePSFKernel(self,Im)

Args = self.Set;
StampSize = size(Im.PSF);
Sigma = Im.PSFData.fwhm/2.355;
p0 = [ceil(StampSize(1)/2),ceil(StampSize(2)/2),Sigma*4,Sigma*4,1e-2,80];
[BestFitPar,Kmin] = ml.pipe.psf.fitPSFKernel(Im.PSF,'model',Args.fitPSFKernelModel,'FitRadius',Args.FitRadiusKernel...
    ,'FitWings',Args.FitWings,'InerRadius',Args.InerRadiusKernel,'p0',p0);

Im.PSF = Kmin;

end
