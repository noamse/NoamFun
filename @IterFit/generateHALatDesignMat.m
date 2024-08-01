function [AhalatX,AhalatY]  = generateHALatDesignMat(IF,Args)

arguments
    IF;
    Args.bins = false;
end





ha = IF.Data.ha(:,1);
alt = IF.Data.alt(:,1);
Hlinear = [ones(size(ha)),sin(ha),cos(ha),sin(alt),cos(alt)];
%H = [Hlinear];
Hquad = [sin(ha).^2,cos(ha).^2,sin(alt).^2,cos(alt).^2];
H = [Hlinear,Hquad];
ZEROS = zeros(size(H));

AhalatX = [H,ZEROS];
AhalatY = [ZEROS,H];
AhalatX(isnan(AhalatX))=0;
AhalatY(isnan(AhalatY))=0;

