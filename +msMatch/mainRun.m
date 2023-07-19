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

[Trans,unPattern] = msMatch.readPatternTrans(Res);

%Obj.Cats = Obj.applyPattern;
Cats = msMatch.applyPattern(Cats,Trans,Args.applyPatternArgs{:});
MatchedMat = msMatch.matchCats(Cats,Args.matchCatsArgs{:});
JD = [Cats.JD];
