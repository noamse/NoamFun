function [ParHalat] = initiateParHalat(IF,Args)

arguments
    IF;
    Args.Chromatic = true;
    %Args.Chrom2D = false;
end

    %ParC = zeros(1,IF.Nepoch);
    
    %ParHalat = zeros(18,IF.Nsrc);
    if IF.ChromaicHighOrder
        ParHalat = zeros(18,IF.Nsrc);
    else
        ParHalat = zeros(6,IF.Nsrc);
    end

    
end



