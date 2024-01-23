function [Acx,Acy]   = generateChromDesignMat(IF,Args)

arguments
    IF;
    Args.Chromatic=true;
    
end

C = median(IF.Data.C)';
Acx = [C,zeros(size(C))];
Acy = [zeros(size(C)),C];

