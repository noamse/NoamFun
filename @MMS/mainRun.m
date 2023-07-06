function  mainRun(Obj,MatchedMat,Args)

arguments
    Obj;
    MatchedMat;
    Args.ReturnCols = {'X','Y','MAG_PSF' ,'FLUX_PSF'...
        ,'fwhm','secz','pa','PSF_CHI2DOF','SN','RefMag'};
    Args.ConfigFilePath = '';
    Args.ColNameX = 'X';
    Args.ColNameY = 'Y';
    Args.ColNameMag = 'MAG_PSF';
end




Obj.addMatrix(MatchedMat,Args.ReturnCols);
% Flag = flagUnmached(Obj,Args); %Maybe implement imedietly? 
RefCoo= Obj.medianFieldSource({'X','Y'});
AffineMat= Obj.fitAffine(RefCoo);
Obj.applyAffineTran(AffineMat);
ZP = Obj.fitRefZP('RefMag');
Obj.applyZP(ZP,'ApplyToMagField',Args.ColNameMag);

end
