function  [Aex,Aey]   = generateEpochDesignMat(AS,Args)

arguments
    AS;
    Args.Chromatic = false;
end


    Aex = [AS.ParS(1,:)',AS.ParS(2,:)',ones(size(AS.ParS(2,:)')),zeros(size(AS.ParS(2,:)')),zeros(size(AS.ParS(2,:)')),zeros(size(AS.ParS(2,:)'))];
    Aey = [zeros(size(AS.ParS(2,:)')),zeros(size(AS.ParS(2,:)')),zeros(size(AS.ParS(2,:)')),AS.ParS(1,:)',AS.ParS(2,:)',ones(size(AS.ParS(2,:)'))];


end