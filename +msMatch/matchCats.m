function MatchedMat = matchCats(Cats,Args)


arguments
    Cats;
    Args.MatchSearchRadius=2;
    Args.RefCatInd=1;
end


MatchedMat = imProc.match.matchedReturnCat(Cats(Args.RefCatInd),Cats,'CooType','pix','Radius',Args.MatchSearchRadius);


end