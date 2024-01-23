function [Mpar,Pars] = diffMatFun(SymModel,ParsRow,ParsCol)
% Function that generate a derivatives fucntions for given two sets of
% paramteters.
%   The function return a symbolic expression that can fill the Nss matrix for a
%   specific source. In addition, the function returns a list containing
%   the syms variables in the derivatives.
arguments
    SymModel = [];
    ParsRow=  [];
    ParsCol= [];
end

if isempty(ParsCol)
    ParsCol = ParsRow;
end


Mpar = sym(zeros(numel(ParsRow),numel(ParsCol)));
for IparCol = 1:numel(ParsCol)
    for IparRow = 1:numel(ParsRow)
        
        Mpar(IparRow,IparCol) = diff(SymModel,ParsCol(IparCol)) * diff(SymModel,ParsRow(IparRow));
        
    end
end
Pars= symvar(Mpar);






       






