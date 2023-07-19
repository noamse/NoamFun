function  mainRun(Obj,MatchedCat,Args)

arguments
    Obj;
    MatchedCat;
    Args.ReturnCols = {'X','Y','MAG_PSF' ,'FLUX_PSF'...
        ,'fwhm','secz','pa','PSF_CHI2DOF','SN','RefMag'};
    Args.ConfigFilePath = '';
    Args.ColNameX = 'X';
    Args.ColNameY = 'Y';
    Args.ColNameMag = 'MAG_PSF';
    Args.fitAffineArgs={};
    Args.fitRefZPArgs={};
    Args.applyZPArgs = {};
    Args.fitProperMotionArgs = {};
    Args.fitAffinePMRefArgs={};
end

JD= [MatchedCat.JD];
if ~isempty(JD)
    Obj.JD = reshape(JD,numel(MatchedCat),1);
end

Obj.addMatrix(MatchedCat,Args.ReturnCols);
% Flag = flagUnmached(Obj,Args); %Maybe implement imedietly? 
RefCoo= Obj.medianFieldSource({'X','Y'});
AffineMat= Obj.fitAffine(RefCoo,Args.fitAffineArgs{:});
Obj.applyAffineTran(AffineMat);
ZP = Obj.fitRefZP('ColNameMag','MAG_PSF','ColNameRefMag','RefMag',Args.fitRefZPArgs{:});
Obj.applyZP(ZP,'ApplyToMagField',Args.ColNameMag,Args.applyZPArgs{:});
[Obj.PMX,Obj.PMY,Obj.PMErr] = Obj.fitProperMotion(Args.fitProperMotionArgs{:});
[XPMRef,YPMRef]= getGlobalRefMat(Obj);

AffineMat = fitAffinePMRef(Obj,XPMRef,YPMRef,Args.fitAffinePMRefArgs{:});
Obj.applyAffineTran(AffineMat);
[Obj.PMX,Obj.PMY,Obj.PMErr] = Obj.fitProperMotion(Args.fitProperMotionArgs{:});




end
