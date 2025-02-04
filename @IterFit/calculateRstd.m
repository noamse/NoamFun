function [RstdX,RstdY] = calculateRstd(IF,Args)

arguments
    IF;
    Args.WeightedRMS= false;
    %Args.PlotY= true;
end


[Rx,Ry] = IF.calculateResiduals;

FlagOut = ~(isoutlier(Rx,'movmedian',30,"ThresholdFactor",1.5,'SamplePoints',IF.JD) ...
        | isoutlier(Ry,'movmedian',30,"ThresholdFactor",1.5,'SamplePoints',IF.JD)...
        | isoutlier(IF.Data.MAG_PSF,'movmedian',30,"ThresholdFactor",1.5,'SamplePoints',IF.JD));
Flag =FlagOut;
Rx(~Flag)=nan;
Ry(~Flag)=nan;
RstdX= rms(Rx,'omitnan')'*400;
RstdY= rms(Ry,'omitnan')'*400;
