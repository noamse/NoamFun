function AffineMat= fitAffine(Obj,RefCoo,Args)
% Fit affine transformation for each epochs in MMS object w.r.t. reference.
%
arguments
    Obj;
    RefCoo;
    Args.Weights= [];
    Args.ColNameX= 'X';
    Args.ColNameY= 'Y';
    Args.PrctileRange = [10,90];
    %               Args.GlobalRef=false;
    %               Args.WeightByPrcVsMag = false;
    %               Args.OnlyMagRange=false;
    %               Args.OnlyOgle = false;
    %               Args.WeightBySN = false;
    %               Args.PrctileRange = [20,80];
    %               Args.FitMaxOgleMag= [];
    %               Args.UseOgleCat = false;
    %               Args.useCovariance = false;
    %               Args.ArgsParCovariance = {'Gamma',-1.2,'A',0.002};
    %               Args.MaxRefMag = [];
    %               Args.RefMagCol = 'RefMag';
    
end

if isempty(Args.Weights)
    Weights = ones(size(RefCoo,1),1);
else
    Weights = Args.Weights;
end



%X = CM.MS.Data.X';
%Y = CM.MS.Data.Y';

%RefX = X(:,1);
%RefY = Y(:,1);
RefX = RefCoo(:,1);
RefY = RefCoo(:,2);
X = Obj.getMatrix(Args.ColNameX)';
Y = Obj.getMatrix(Args.ColNameY)';
AffineMat = cell(Obj.Nepoch,1);
%             if Args.WeightByPrcVsMag
%                 MagStdsq = (std(CM.MS.Data.err,'omitnan').^2)';
%             end
for Iepoch =1:Obj.Nepoch
    
    %                 if Args.GlobalRef
    %
    %                     RefCat_ast = CM.create_reference(CM.MS.JD(i));
    %                     RefX=RefCat_ast.getCol('X');
    %                     RefY=RefCat_ast.getCol('Y');
    %                 end
    
    %H = [X(i,:)',Y(i,:)',ones(size(RefX'))];
    H = Obj.designMatrixEpoch(Iepoch,{'X','Y',[]}, {1,1,[]});
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
    
    isout= isoutx|isouty;
    %isout= false(size(isouty));

    ax = lscov(Ht(~isout,:),Xt(~isout),wt(~isout));
    ay = lscov(Ht(~isout,:),Yt(~isout),wt(~isout));
    AffineMat{Iepoch} = [ax';ay';0,0,1];
    
end
% Fit affine transformations

end