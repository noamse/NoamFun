function run_pipe(DirCell,AstCatSavePath,Args)

arguments
    DirCell;
    AstCatSavePath;
    Args.IndStepSize = 1;
    Args.DispInd = true;
    Args.IndList = [];
    Args.OgleCatFieldName='ogle_cat';
end


Set = readPipeParameters(AstCatSavePath);
%ogle_cat = load([AstCatPath Args.SavedCatFileName],'ogle_cat');
ogle_cat= readOgleCatalog(AstCatSavePath,'CatFieldName',Args.OgleCatFieldName);
if isempty(Args.IndList )
    IndList = 1:Args.IndStepSize:numel(DirCell);
else
    IndList= Args.IndList ;
end
DisplayInd = Args.DispInd;
parfor Ind=IndList
    if DisplayInd 
        disp(Ind);
    end
    ml.pipe.pipe_image(DirCell{Ind},Ind,'SaveFile',Set.SaveFile,'AstCatSavePath',Set.AstCatSavePath...
        ,'CCDSEC_xd',Set.CCDSEC_xd,'CCDSEC_xu',Set.CCDSEC_xu,'CCDSEC_yd',Set.CCDSEC_yd,'CCDSEC_yu',Set.CCDSEC_yu,...
        'HalfSize',Set.HalfSize,'mexCutout',Set.mexCutout,'FitRadius',Set.FitRadius,...
        'UseSourceNoise',Set.UseSourceNoise,'PSFfitmaxStep',Set.PSFfitmaxStep,'PSFfitConvThresh',Set.PSFfitConvThresh,'PSFfitMaxIter',Set.PSFfitMaxIter,...
        'SNRforPSFConstruct',Set.SNRforPSFConstruct,...
        'OgleCat',ogle_cat,'ExtractWithRef',Set.ExtractWithRef,'NRefMagBin',Set.NRefMagBin,'FitWings',Set.FitWings...
        ,'fitPSFKernelModel',Set.fitPSFKernelModel,'FitRadiusKernel',Set.FitRadiusKernel,'PSFSmallStep',Set.PSFSmallStep,...
        'UseKernelPSFPhotometry',Set.UseKernelPSFPhotometry);
end







end