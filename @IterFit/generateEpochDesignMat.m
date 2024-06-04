function  [Aex,Aey]   = generateEpochDesignMat(IF,Args)

arguments
    IF;
    Args.Chromatic = false;
end

% if IF.Chromatic 
%     C = median(IF.Data.C)';
%     Aex = [IF.ParS(1,:)',IF.ParS(2,:)',ones(size(IF.ParS(2,:)')),...
%         zeros(size(IF.ParS(2,:)')),zeros(size(IF.ParS(2,:)')),zeros(size(IF.ParS(2,:)')),...
%         C,zeros(size(C))];
%     Aey = [zeros(size(IF.ParS(2,:)')),zeros(size(IF.ParS(2,:)')),zeros(size(IF.ParS(2,:)')),...
%         IF.ParS(1,:)',IF.ParS(2,:)',ones(size(IF.ParS(2,:)')),...
%         zeros(size(C)),C];
% else
    Aex = [IF.ParS(1,:)',IF.ParS(2,:)',ones(size(IF.ParS(2,:)')),zeros(size(IF.ParS(2,:)')),zeros(size(IF.ParS(2,:)')),zeros(size(IF.ParS(2,:)'))];
    Aey = [zeros(size(IF.ParS(2,:)')),zeros(size(IF.ParS(2,:)')),zeros(size(IF.ParS(2,:)')),IF.ParS(1,:)',IF.ParS(2,:)',ones(size(IF.ParS(2,:)'))];
% end


end