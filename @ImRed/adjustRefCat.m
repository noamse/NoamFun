function RefCat  = adjustRefCat(self,Im,Args) % tbd

arguments
    self;
    Im;
    Args.RefColNameMag= 'I';
    Args.MaxRefMagPattern = 17;
    Args.MatchRadius = 4;
    Args.AffineScale = [0.8,1.2];
    Args.PatternRange = [-100,100];
    Args.MatchRadiusPattern = 1;
    Args.PatternStep = 0.1;
end
RefCat = self.RefCatalog.copy();













% Fit Pattern
RefCatBright = self.RefCatalog.copy();
Imag= RefCatBright.getCol(Args.RefColNameMag);
FlagMag = Imag<Args.MaxRefMagPattern;%median(ImagClip,'omitnan');
RefCatBright.Catalog = RefCatBright.Catalog(FlagMag,:);
try
ResultMatch = imProc.match.matchReturnIndices(Im.CatData,RefCatBright,'Radius',Args.MatchRadius );
MatchedFlagRefCat= ResultMatch.Obj1_IndInObj2(~isnan(ResultMatch.Obj1_IndInObj2));
MatchedFlagRefImCat = ResultMatch.Obj1_FlagNearest;

if isempty(MatchedFlagRefCat) || sum(MatchedFlagRefImCat)<1
    RefCat = AstroCatalog;
    return;
end

XYIm= Im.CatData.getCol({'X1','Y1'});
XYIm = XYIm(MatchedFlagRefImCat,:);
XYRef = RefCatBright.getCol({'X','Y'});
XYRef = XYRef(MatchedFlagRefCat,:);



    [ResAffine] = imProc.trans.fitPattern(XYIm,XYRef,'Scale',Args.AffineScale...
        ,'RangeX',Args.PatternRange ,'RangeY',Args.PatternRange ,'StepX',Args.PatternStep,'StepY',Args.PatternStep,...
        'MaxMethod','max1','SearchRadius',Args.MatchRadiusPattern,'Flip',[1 1]);
    [NewX,NewY]=imUtil.cat.affine2d_transformation([RefCat.getCol('X'),RefCat.getCol('Y')],ResAffine.Sol.AffineTran{1},'+'...
        ,'ColX',1,'ColY',2);
catch
    disp('Failed to fitPattern')
    RefCat=AstroCatalog;
    return;
end

RefCat.Catalog(:,RefCat.colname2ind({'X','Y'})) = [NewX,NewY];    
% Filter reference sources. 
X = RefCat.getCol('X');
Y = RefCat.getCol('Y');
%Imag = RefCat.getCol('I');
[Szim1,Szim2] =Im.sizeImage;
FlagOutBound= X>1 & Y>1  & X<Szim1& Y<Szim2;
RefCat.Catalog = RefCat.Catalog(FlagOutBound,:);

% if sum(FlagOutBound)<0.5*numel(FlagOutBound)
%     
%     RefCat = AstroCatalog;
%     return;
end


