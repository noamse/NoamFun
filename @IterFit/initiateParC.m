function [ParC] = initiateParC(IF,Args)

arguments
    IF;
    Args.Chromatic = true;
    %Args.Chrom2D = false;
end

    %ParC = zeros(1,IF.Nepoch);
    if IF.Chrom2D
        ParC = zeros(2,IF.Nepoch);
    else
        ParC = zeros(1,IF.Nepoch);
    end
end



