function [MatchedMat,JD]= mainRun(Obj,Cats,Args)

arguments
   Obj;
   Cats;
   Args.fitPatternArgs={};
   Args.applyPatternArgs= {};
   Args.matchCatsArgs = {};
end


Cats = Cats(~Cats.isemptyCatalog);
Obj.Cats=Cats;
[Res]= fitPattern(Obj,Args.fitPatternArgs{:});

[Trans,unPattern] = readPatternTrans(Obj,Res);

%Obj.Cats = Obj.applyPattern;
Obj.Cats = applyPattern(Obj,Trans,Args.applyPatternArgs{:});
MatchedMat = matchCats(Obj,Args.matchCatsArgs{:});
JD = [Obj.Cats.JD];
