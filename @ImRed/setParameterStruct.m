function Args= setParameterStruct(CatPathTarget,Args)
arguments
    
    CatPathTarget;
    Args.CCDSEC_xd = 400;
    Args.CCDSEC_xu = 800;
    Args.CCDSEC_yd = 400;
    Args.CCDSEC_yu = 800;
    Args.SaveFile=true;
    Args.HalfSize= 10;
    Args.SNRforPSFConstruct = 70;
    Args.FitRadius=3;
    Args.InerRadiusKernel = 2;
    Args.FindMeasureRemoveBad= true;
    Args.Telescope= 'CTIO';
    Args.findMeasureSourceUsePSF = true;
    Args.UseKernelPSFPhotometry = true;
    Args.UseSourceNoise = true;
    Args.MaxRefMag = 19;
    Args.NRefMagBin=8;
    Args.FitWings=true;
    Args.fitPSFKernelModel='mtd';
    Args.FitRadiusKernel = 5;
    Args.Band=  'I';
    Args.Dmin_thresh = 3; Args.DistFromBound = 8;
    Args.SettingFileName = 'master.txt';
    Args.MaxRefMagPattern = 17;
    Args.ReCalcBack = true;
    %Args.max_I = 18.3;
    %Args.mexCutout=true;
    %Args.ExtractWithRef = true;
    %Args.PSFfitConvThresh= 1e-5;
    %Args.PSFfitMaxIter = 50;
    %Args.PSFSmallStep = 1e-6;
    %Args.PSFfitmaxStep = 0.8;
    %Args.threshold_im= 5;
    %Args.DirCellPath  = '/home/noamse/astro/KMT_ML/data/results/ob190506/DirCell.mat';
end
Args.AstCatSavePath = CatPathTarget;
mkdir(Args.AstCatSavePath);
writetable(struct2table(Args), [Args.AstCatSavePath Args.SettingFileName ])









%Args.Band=  'V';z

