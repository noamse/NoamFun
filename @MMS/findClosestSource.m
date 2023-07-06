function Ind = findClosestSource(Obj,Coo,Args)

arguments
    Obj;
    Coo;
    Args.ColNameX = 'X';
    Args.ColNameY = 'Y';
end
XY= Obj.medianFieldSource({Args.ColNameX,Args.ColNameY});
D = sqrt(nansum((XY-Coo).^2,2));
[~,Ind] = min(D(D>0));



end