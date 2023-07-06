function matchObj(MO,Args)
% Match catalog and populate the MatchedSources property of MLObj. 
%
arguments
    MO;
    Args.MatchRadius = 1;
    Args.matchObjReturnCols = {'X','Y','MAG_PSF' ,'FLUX_PSF'...
            ,'fwhm','secz','pa','PSF_CHI2DOF','SN','RefMag'};
end

Matched = imProc.match.matchedReturnCat(MO.RefCat,MO.AstCat,'CooType','pix','Radius',Args.MatchRadius);

MO.MS.addMatrix(Matched,Args.matchObjReturnCols);


end
