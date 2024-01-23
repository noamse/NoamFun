function [MatchedMat,JD]= mainRun(Cats,Args)

arguments
   Cats;
   Args.fitPatternArgs={};
   Args.applyPatternArgs= {};
   Args.matchCatsArgs = {};
end


Cats = Cats(~Cats.isemptyCatalog);
%Obj.Cats=Cats;
[Res]= msMatch.fitPattern(Cats,Args.fitPatternArgs{:});

[Trans,FlagFailed] = msMatch.readPatternTrans(Res);

%Obj.Cats = Obj.applyPattern;
Cats = Cats(FlagFailed);
JD = [Cats.JD];
Trans = Trans(FlagFailed);
Cats = msMatch.applyPattern(Cats,Trans,Args.applyPatternArgs{:});
MatchedMat = msMatch.matchCats(Cats,Args.matchCatsArgs{:});
JD = [Cats.JD];
