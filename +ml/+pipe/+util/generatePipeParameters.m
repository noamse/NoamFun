function Args= generatePipeParameters(SavePath,Args)
arguments
    %Args.DirCellPath  = '/home/noamse/astro/KMT_ML/data/results/ob190506/DirCell.mat';
    SavePath;
    %Args.CCDSEC_im = [400,800,400,800];
    Args.CCDSEC_xd = 400;
    Args.CCDSEC_xu = 800;
    Args.CCDSEC_yd = 400;
    Args.CCDSEC_yu = 800;

    Args.threshold_im= 5; 
    Args.mexCutout=true; 
    Args.SaveFile=true; 
    Args.HalfSize= 10;
    %Args.SNRThresh = [600,300,150,50,20]; 
    Args.UseReverseIter = false; 
    Args.SNRforPSFConstruct = 70;
    Args.FitRadius=3; 
    Args.FindMeasureRemoveBad= true;
    Args.Telescope= 'CTIO';
    Args.prctile_th=50;
    Args.findMeasureSourceUsePSF = true; 
    Args.UseKernelPSFPhotometry = true;
    Args.UseSourceNoise = 'all'; 
    Args.max_I = 19;
    Args.NRefMagBin=8; 
    Args.FitWings=true; 
    Args.fitPSFKernelModel='mtd';
    Args.FitRadiusKernel = 5; 
    Args.PSFfitConvThresh= 1e-5; 
    Args.PSFfitMaxIter = 50; 
    Args.PSFSmallStep = 1e-6; 
    Args.PSFfitmaxStep = 0.8;
    Args.Band=  'I'; 
    Args.Dmin_thresh = 3; Args.DistFromBound = 8;
    Args.OgleMatchRadius= 1;
    Args.OnlyOgleSource = true;  
    Args.ExtractWithRef = true;
    Args.SettingFileName = 'master.txt';
    
end
Args.AstCatSavePath = SavePath;
mkdir(Args.AstCatSavePath);
writetable(struct2table(Args), [Args.AstCatSavePath Args.SettingFileName ])









%Args.Band=  'V';z

