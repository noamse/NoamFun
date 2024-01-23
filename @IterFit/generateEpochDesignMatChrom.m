function  [Aex,Aey]   = generateEpochDesignMatChrom(IF)

arguments
    IF;
    
end
Aex = [IF.ParS(1,:)',IF.ParS(2,:)',ones(size(IF.ParS(2,:)')),zeros(size(IF.ParS(2,:)')),zeros(size(IF.ParS(2,:)')),zeros(size(IF.ParS(2,:)'))];
Aey = [zeros(size(IF.ParS(2,:)')),zeros(size(IF.ParS(2,:)')),zeros(size(IF.ParS(2,:)')),IF.ParS(1,:)',IF.ParS(2,:)',ones(size(IF.ParS(2,:)'))];



end