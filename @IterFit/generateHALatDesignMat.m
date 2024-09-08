function [AhalatX,AhalatY]  = generateHALatDesignMat(IF,Args)

arguments
    IF;
    Args.bins = false;
end





%ha = IF.Data.ha(:,1);
%alt = IF.Data.alt(:,1);
%Hlinear = [ones(size(ha)),sin(ha),cos(ha),sin(alt),cos(alt)];
%H = [Hlinear];
%Hquad = [sin(ha).^2,cos(ha).^2,sin(alt).^2,cos(alt).^2];
pa= IF.Data.pa(:,1);
secz= IF.Data.secz(:,1);
sinPA = sin(pa);
cosPA= cos(pa);


if IF.ChromaicHighOrder
    Hlinear = [ones(size(sinPA)),sinPA.*secz,cosPA.*secz];%,sin(alt),cos(alt)];
    Hquad = [sinPA.^2,cosPA.^2,sinPA.^3,cosPA.^3,sinPA.^4,cosPA.^4].*secz;
    H = [Hlinear,Hquad];
else
    Hlinear = [ones(size(sinPA)),sinPA.*secz,cosPA.*secz];%,sin(alt),cos(alt)];
    H= Hlinear;
end
ZEROS = zeros(size(H));

AhalatX = [H,ZEROS];
AhalatY = [ZEROS,H];
AhalatX(isnan(AhalatX))=0;
AhalatY(isnan(AhalatY))=0;

