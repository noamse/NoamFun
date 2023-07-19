function AffineMat= fitAffinePMRef(Obj,XPMRef,YPMRef,Args)
arguments
    Obj;
    XPMRef;
    YPMRef;
    Args.Weights= [];
    Args.ColNameX= 'X';
    Args.ColNameY= 'Y';
    Args.PrctileRange = [10,90];
    Args.MaxRefMag = [];
    Args.ColNameRefMag = 'RefMag';
    
end







RefX = XPMRef';
RefY = YPMRef';
X = Obj.getMatrix(Args.ColNameX)';
Y = Obj.getMatrix(Args.ColNameY)';
AffineMat = cell(Obj.Nepoch,1);
if isempty(Args.Weights)
    Weights = ones(size(RefX(:,1),1),1);
else
    Weights = Args.Weights;
end

if ~isempty(Args.MaxRefMag)
    Mag = Obj.medianFieldSource({Args.ColNameRefMag});
    FlagMag = Mag<Args.MaxRefMag;
    RefX = RefX(FlagMag,:);
    RefY = RefY(FlagMag,:);
    X  = X(FlagMag,:);
    Y  = Y(FlagMag,:);
end


for Iepoch =1:Obj.Nepoch
    
    H = Obj.designMatrixEpoch(Iepoch,{'X','Y',[]}, {1,1,[]});
    if ~isempty(Args.MaxRefMag)
        H = H(FlagMag,:);
    end
    Flag = ~isnan(X(:,Iepoch))&~isnan(Y(:,Iepoch)) &~isnan(RefX(:,Iepoch))&~isnan(RefY(:,Iepoch));
    
    Ht = H(Flag,:);
    Xt = RefX(Flag,Iepoch);
    Yt = RefY(Flag,Iepoch);
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
