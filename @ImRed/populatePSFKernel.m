function Im   = populatePSFKernel(self,Im)

Args = self.Set;
StampSize = size(Im.PSF);
Sigma = Im.PSFData.fwhm/2.355;
p0 = [ceil(StampSize(1)/2),ceil(StampSize(2)/2),Sigma,Sigma,-1e-3,3];
[~,Kmin] = ml.pipe.psf.fitPSFKernel(Im.PSF,'model',Args.fitPSFKernelModel,'FitRadius',Args.FitRadiusKernel...
    ,'FitWings',Args.FitWings,'InerRadius',Args.InerRadiusKernel,'p0',p0);

Im.PSF = Kmin;

end
