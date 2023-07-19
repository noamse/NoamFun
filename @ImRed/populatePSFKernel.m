function Im   = populatePSFKernel(self,Im)

Args = self.Set;


[~,Kmin] = ml.pipe.psf.fitPSFKernel(Im.PSF,'model',Args.fitPSFKernelModel,'FitRadius',Args.FitRadiusKernel...
    ,'FitWings',Args.FitWings,'InerRadius',Args.InerRadiusKernel);

Im.PSF = Kmin;

end
