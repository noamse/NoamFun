function [MatchedMat,JD,Trans]= mainRun(Cats,Args)

arguments
   Cats;
   Args.fitPatternArgs={};
   Args.applyPatternArgs= {};
   Args.matchCatsArgs = {};
   Args.UseReference
   Args.RefCat = [];
end

Flag = ~Cats.isemptyCatalog & Cats.isColumn({'X'}) & Cats.isColumn({'Y'});
Cats = Cats(Flag);
%Obj.Cats=Cats;

[Res]= msMatch.fitPattern(Cats,'RefCat',Args.RefCat,Args.fitPatternArgs{:});

[Trans,FlagFailed] = msMatch.readPatternTrans(Res);

%Obj.Cats = Obj.applyPattern;
Cats = Cats(FlagFailed);
JD = [Cats.JD];
Trans = Trans(FlagFailed);
Cats = msMatch.applyPattern(Cats,Trans,Args.applyPatternArgs{:});
MatchedMat = msMatch.matchCats(Cats,Args.matchCatsArgs{:});
JD = [Cats.JD];
