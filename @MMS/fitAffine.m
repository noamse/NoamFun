function AffineMat= fitAffine(Obj,RefCoo,Args)
% Fit affine transformation for each epochs in MMS object w.r.t. reference.
%
arguments
    Obj;
    RefCoo;
    Args.Weights= [];
    Args.ColNameX= 'X';
    Args.ColNameY= 'Y';
    Args.PrctileRange = [15,85];
    Args.MaxRefMag = [];
    Args.ColNameRefMag = 'RefMag';
    %               Args.OnlyMagRange=false;
    %               Args.FitMaxOgleMag= [];
    %               Args.MaxRefMag = [];
    %               Args.RefMagCol = 'RefMag';
    
end

if isempty(Args.Weights)
    Weights = ones(size(RefCoo,1),1);
else
    Weights = Args.Weights;
end



RefX = RefCoo(:,1);
RefY = RefCoo(:,2);


X = Obj.getMatrix(Args.ColNameX)';
Y = Obj.getMatrix(Args.ColNameY)';
if ~isempty(Args.MaxRefMag)
    Mag = Obj.medianFieldSource({Args.ColNameRefMag});
    FlagMag = Mag<Args.MaxRefMag;
    RefX = RefX(FlagMag);
    RefY = RefY(FlagMag);
    X  = X(FlagMag,:);
    Y  = Y(FlagMag,:);
end

AffineMat = cell(Obj.Nepoch,1);
for Iepoch =1:Obj.Nepoch
    
    H = Obj.designMatrixEpoch(Iepoch,{'X','Y',[]}, {1,1,[]});
    if ~isempty(Args.MaxRefMag)
        H = H(FlagMag,:);
    end
    %{
    %MAG_PSF=CM.MS.Data.MAG_PSF(i,:)';
    
    
    %FLUX_PSF = CM.MS.Data.FLUX_PSF(i,:)';
    %if Args.WeightByPrcVsMag % Based on residuals
    %
    %    w = (1./CM.MS.Data.err(i,:)').^2;
    
    %elseif Args.WeightBySN % No weight
    %    w = (CM.MS.Data.SN(i,:)').^2;
    %else
    %    w = ones(size(FLUX_PSF));
    %end
    
    %if Args.useCovariance
    %    w = CM.astrometricCovariance('Diagonal',MagStdsq);
    %end
    %if Args.OnlyOgle
    
    %    RefX= RefX(CM.matched_flag_ref_cat);
    %    RefY= RefY(CM.matched_flag_ref_cat);
    %    if Args.useCovariance
    %        w = w(CM.matched_flag_ref_cat,CM.matched_flag_ref_cat);
    %    else
    %         w = w(CM.matched_flag_ref_cat);
    %    end
    
    %    MAG_PSF = MAG_PSF(CM.matched_flag_ref_cat);
    %    H = H(CM.matched_flag_ref_cat,:);
    %    Imag = CM.OgleCat.getCol('I');
    %    Imag = Imag(CM.matched_flag_ogle_cat);
    %end
    
    
    
    
    
    %Flag = ~isnan(X(:,i))&~isnan(Y(:,i)) &~isnan(RefX)...
    %    &~isnan(RefY) & ~isnan(w) &w>0 & interp_1ow +interp_std>1./w;
    %if isempty(Args.FitMaxOgleMag)
    %    Flag = ~isnan(X(:,Iepoch))&~isnan(Y(:,Iepoch)) &~isnan(RefX)...
    %        &~isnan(RefY) & ~isnan(w(:,1));
    %else
    %    Flag = ~isnan(X(:,Iepoch))&~isnan(Y(:,Iepoch)) &~isnan(RefX)...
    %        &~isnan(RefY) & ~isnan(w(:,1)) & Imag<Args.FitMaxOgleMag;
    %end
    %}
    Flag = ~isnan(X(:,Iepoch))&~isnan(Y(:,Iepoch)) &~isnan(RefX)&~isnan(RefY);
    
    Ht = H(Flag,:);
    Xt = RefX(Flag);
    Yt = RefY(Flag);
    wt = Weights(Flag);
    
    
    
    ax = lscov(Ht,Xt,wt);
    ay = lscov(Ht,Yt,wt);
    
    isoutx = isoutlier(Ht*ax-Xt,'percentile',Args.PrctileRange);
    isouty= isoutlier(Ht*ay-Yt,'percentile',Args.PrctileRange);
    
    FlagO= ~(isoutx|isouty);
    %isout= false(size(isouty));

    ax = lscov(Ht(FlagO,:),Xt(FlagO),wt(FlagO));
    ay = lscov(Ht(FlagO,:),Yt(FlagO),wt(FlagO));
    AffineMat{Iepoch} = [ax';ay';0,0,1];
    
end
% Fit affine transformations

end