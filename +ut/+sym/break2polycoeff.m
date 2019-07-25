function [coeff,coeffOrder] = break2polycoeff(SymFun,varargin)
%{
break a funtion to simple polynom coefficient
%}

DefV.Dim = 2;
DefV.Order = 4;

InPar = InArg.populate_keyval(DefV,varargin,mfilename);


coeff = zeros(1,InPar.Order+1);

coeffOrder = zeros(InPar.Dim,InPar.Order+1);
ind = 1;
syms X Y df(X,Y);
for i= 1:(InPar.Order+1)
    for j= 1:(InPar.Order+1)
        df(X,Y)= diff(diff(SymFun,i-1,X),j-1,Y);
        coeff(ind)= df(0,0)/(factorial(i-1).*factorial(j-1));
        coeffOrder(1,ind) = i-1;
        coeffOrder(2,ind) = j-1;
        ind = ind+1;
    end
end



end