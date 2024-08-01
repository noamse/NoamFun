function [RstdX,RstdY] = calculateRstd(IF,Args)

arguments
    IF;
    Args.WeightedRMS= false;
    %Args.PlotY= true;
end


[Rx,Ry] = IF.calculateResiduals;

FlagOut = ~(isoutlier(Rx,1) | isoutlier(Ry,1)| isoutlier(sqrt(Ry.^2 + Rx.^2),1));
Flag =FlagOut;
Rx(~Flag)=nan;
Ry(~Flag)=nan;
RstdX= rms(Rx,'omitnan')'*400;
RstdY= rms(Ry,'omitnan')'*400;
