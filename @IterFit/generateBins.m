function [NC,edgesC,binC] = generateBins(IF,Args)

arguments
    IF;
    Args.CBinWidth=0.5;
    Args.ClearBadColor = true;
end

if isempty(IF.CBinWidth)
    CBinWidth = Args.CBinWidth;
else
    CBinWidth =IF.CBinWidth;
end


[NC,edgesC,binC] = histcounts(IF.Data.C(1,:)','BinWidth',CBinWidth);

if Args.ClearBadColor 
    binC(IF.Data.C(1,:)'<-9)=0;
end


end
