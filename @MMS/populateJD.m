function populateJD(Obj,MatchedMat,Args)
arguments
   Obj;
   MatchedMat;
   Args.Dimension = 1;    % 1 for size = (Nepoch,1) and 2 for (1,Nepoch)
end

JD = [MatchedMat.JD];