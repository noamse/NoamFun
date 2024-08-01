function [Acx,Acy]   = generateChromDesignMat(IF,Args)

arguments
    IF;
    Args.Chromatic=true;
    
end




%Acx = IF.Data.C.*sin(IF.Data.pa);
%Acy = IF.Data.C.*cos(IF.Data.pa);


C = median(IF.Data.C)';
%Acx = [C,zeros(size(C))];
%Acy = [zeros(size(C)),C];
if IF.Chrom2D
    Acx = [C,zeros(size(C))];
    Acy = [zeros(size(C)),C];
else
    Acx = C;
    Acy = C;
end

%Acx=C;
%Acy=C;
