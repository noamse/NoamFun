function [Obj,CelestialCoo,Matched]= loadAstCatMatch(TargetPath)

addpath('/home/noamse/astro/KMT_ML/code/func/')
%TargetPath ='/data1/noamse/KMT/data/AstCats/Aug23/kmt161569/';
%TargetPath  = '/home/noamse/KMT/data/AstCats/results/kmt192630/';
%TargetPath ='/data1/noamse/KMT/data/AstCats/Aug23/kmt161214/';

%TargetPath ='/home/noamse/KMT/data/AstCats/Aug23/kmt162069/';
%TargetPath = '/home/noamse/KMT/data/AstCats/test1/kmt180095/';
astcats  = ml.util.readAstCats(TargetPath,'NamePattern','AstCat','CatFieldName','Cat');

RefSt=load([TargetPath,'RefCat.mat']);
RefSt.RefCat.sortrows('Y');

[MatchedCat,JD,~]  = msMatch.mainRun(astcats,'RefCat',RefSt.RefCat);
Obj = MMS; 
Obj.JD = JD';
%Obj.mainRun(MatchedCat,'RefCat',RefSt.RefCat,'FitPlx',true);
%RefCat  = RefSt.RefCat.copy();
%RefCat.
Obj.mainRun(MatchedCat,'RefCat',RefSt.RefCat,'FitPlx',false,'AdditionalPMRefIteration',false,...
    'fitProperMotionLogical',false,'fitAffineArgs',{'MaxRefMag',17},'UseRefCat',false,'fitRefZPArgs',{'ZPFun',@median,'ZPFunArgs',{'omitnan'}});
[Matched]   = matchToRefCat(Obj,RefSt.RefCat,'MatchRadius',2);

%Matched = RefSt.RefCat.copy();
C = Matched.getCol('V-I');
RefMag = Matched.getCol('I');
%Obj.Data.C = (C - median(C(RefMag<16),'omitnan'))'.*ones(size(Obj.Data.X));
CelestialCoo = median(RefSt.RefCat.getCol({'RA','Dec'}))/180*pi;
Obj.Data.C = (C - median(C,'omitnan'))'.*ones(size(Obj.Data.X));
