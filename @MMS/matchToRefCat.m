function [Matched]   = matchToRefCat(Obj,RefCat,Args)

arguments
    Obj;
    RefCat;
    Args.MatchRadius = 2;
    
    
    
    
end

QueryMat = Obj.medianFieldSource({'X','Y','RefMag'});
QueryCat = AstroCatalog({QueryMat},'ColNames',{'X','Y','RefMag'});

Matched = imProc.match.matchedReturnCat(QueryCat,RefCat,'CooType','pix','Radius',Args.MatchRadius);
