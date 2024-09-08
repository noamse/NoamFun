function  mainRun(Obj,MatchedCat,Args)

arguments
    Obj;
    MatchedCat;
    Args.ReturnCols = {'X','Y','MAG_PSF' ,'FLUX_PSF'...
        ,'fwhm','secz','pa','PSF_CHI2DOF','SN','RefMag','DeltaPSFXY'...
        ,'EXPTIME','FATILTEW','FATILTNS','FAFOCUS','CCDTEMP'...
        ,'ha','alt','Yphase', 'Xphase'};
    Args.ConfigFilePath = '';
    Args.ColNameX = 'X';
    Args.ColNameY = 'Y';
    Args.ColNameMag = 'MAG_PSF';
    Args.fitAffineArgs={'MaxRefMag',19};
    Args.fitRefZPArgs={};
    Args.applyZPArgs = {};
    Args.fitProperMotionArgs = {};
    Args.fitAffinePMRefArgs={'MaxRefMag',17.5,'MinRefMag',14.5};
    Args.AdditionalPMRefIteration=false
    Args.photometryOutliersArgs = {'SigmaClip',2};
    Args.fitPlx = false;
    Args.RefCat=[];
    Args.fitProperMotionLogical = true;
    Args.UseRefCat  =false;
    Args.RemovePhotometricOutliers = false;
end

JD= [MatchedCat.JD];
if ~isempty(JD)
    Obj.JD = reshape(JD,numel(MatchedCat),1);
end

Obj.addMatrix(MatchedCat,Args.ReturnCols);
% Flag = flagUnmached(Obj,Args); %Maybe implement imedietly?
if Args.UseRefCat & isa(Args.RefCat,'AstroCatalog')
    RefCoo = Args.RefCat.getCol({'X','Y'});
else
    RefCoo= Obj.medianFieldSource({'X','Y'});
end
AffineMat= Obj.fitAffine(RefCoo,Args.fitAffineArgs{:});
Obj.applyAffineTran(AffineMat);
ZP = Obj.fitRefZP('ColNameMag','MAG_PSF','ColNameRefMag','RefMag',Args.fitRefZPArgs{:});
Obj.applyZP(ZP,'ApplyToMagField',Args.ColNameMag,Args.applyZPArgs{:});
if Args.RemovePhotometricOutliers
    [Out]  = photometryOutliers(Obj,Args.photometryOutliersArgs{:});
    Obj.applySourceFlag(~Out);
end
if Args.fitProperMotionLogical
    [Obj.PMX,Obj.PMY,Obj.PMErr] = Obj.fitProperMotion(Args.fitProperMotionArgs{:});
    [XPMRef,YPMRef]= getGlobalRefMat(Obj);
    %[Out]  = photometryOutliers(Obj,Args.photometryOutliersArgs{:});
    %Obj.applySourceFlag(~Out);
    T = Obj.medianFieldSource({'PSF_CHI2DOF','FLUX_PSF'});
    Weights = 1./(T(:,1)./T(:,2));
    Weights(Weights<median(Weights))=nan;
    %Weights = ones(size(T(:,1)));
    AffineMat = fitAffinePMRef(Obj,XPMRef,YPMRef,'Weights',Weights,Args.fitAffinePMRefArgs{:});
    Obj.applyAffineTran(AffineMat);
    [Obj.PMX,Obj.PMY,Obj.PMErr] = Obj.fitProperMotion(Args.fitProperMotionArgs{:});
    
    if Args.AdditionalPMRefIteration
        %[Out]  = photometryOutliers(Obj,Args.photometryOutliersArgs{:});
        
        [XPMRef,YPMRef]= getGlobalRefMat(Obj);
        
        AffineMat = fitAffinePMRef(Obj,XPMRef,YPMRef,Args.fitAffinePMRefArgs{:});
        Obj.applyAffineTran(AffineMat);
        
    end
    
    if Args.fitPlx
        if isempty(Args.RefCat)
            disp('RefCat is empty. Cannot fi for parallax.');
            
        else
            RefCat = Args.RefCat;
            [Matched]   = Obj.matchToRefCat(RefCat);
            RADec  =Matched.getCol({'RA','Dec'})/180*pi;
            [Obj.PMPlx,Obj.PMPlxErr]   = fitProperMotionPlx(Obj,'Coo',RADec);
        end
        
    end
    
end
