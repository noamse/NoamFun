function   Im  = constructPSF(self,Im,Args)
arguments
   self;
   Im;
   Args.findMeasureSourcesArgs = {'Threshold',60,'PsfFunPar',{[0.5; 1.0; 1;]},...
       'RemoveBadSources',true,'ReCalcBack',true};
   Args.constructPSFSmoothWings = true;
   Args.HalfSize = 10;
   
end
Im = imProc.sources.findMeasureSources(Im,Args.findMeasureSourcesArgs{:});
[Im] =imProc.psf.constructPSF(Im,'constructPSF_cutoutsArgs',{'MedianCubeSumRange',[0.8 4]...
    ,'CubeSumRange',[0.8 4],'SmoothWings',Args.constructPSFSmoothWings,...
    'psf_zeroConvergeArgs',{'Radius',Args.HalfSize}},'HalfSize',Args.HalfSize...
    ,'selectPsfStarsArgs',{'RangeSN',[10,500]});


end