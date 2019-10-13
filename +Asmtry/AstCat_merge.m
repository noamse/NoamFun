function [astcat_full]= AstCat_merge(SubAstCat ,varargin)


% Trim AstCat object by user specified criteria.




%InPar = InArg.populate_keyval(DefV,varargin,mfilename);

N = numel(SubAstCat);

astcat_full = SubAstCat(1);
astcat_full.Cat=[];
for i= 1:N
    
    astcat_full.Cat = [astcat_full.Cat ; SubAstCat(i).Cat];
end
end