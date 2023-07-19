function MatchedMat = matchCats(Obj,Args)


arguments
    Obj;
    Args.MatchSearchRadius=2;
    Args.RefCatInd=1;
end


MatchedMat = imProc.match.matchedReturnCat(Obj.Cats(Args.RefCatInd),Obj.Cats,'CooType','pix','Radius',Args.MatchSearchRadius);


end