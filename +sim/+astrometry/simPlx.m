function [Xplx,Yplx] = simPlx(Plx,CelCoo,Ecoo)

    Xearth = Ecoo(1,:);
    Yearth = Ecoo(2,:);
    Zearth = Ecoo(3,:);
    RA= CelCoo(1);
    Dec= CelCoo(2);
    RAPlxTerm= -(Xearth.*sin(RA)- Yearth.*cos(RA));
    DecPlxTerm= (Xearth.*cos(RA).*sin(RA) + ...
    Yearth.*sin(RA).*sin(Dec) - Zearth.*cos(Dec));
    Xplx = reshape(Plx,numel(Plx),1)*RAPlxTerm;
    Yplx = reshape(Plx,numel(Plx),1)*DecPlxTerm;
    
end