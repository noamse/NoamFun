function [RStdPrcX,RStdPrcY,M] = plotResRMS(IF,Args)

arguments
    IF;
    Args.closeall = false;
    Args.title = '';
    Args.PlotY= true;
end
[Rx,Ry] = IF.calculateResiduals;
Wes=  IF.calculateWes;
Wes=median(Wes,2);
Wes = Wes/max(Wes);
FlagW = Wes>0.8;
FlagOut = ~(isoutlier(Rx,1) | isoutlier(Ry,1));
Flag = logical(FlagOut.*FlagW);
Flag =FlagOut;
Rx(~Flag)=nan;
Ry(~Flag)=nan;
RStdPrcX= rms(Rx,'omitnan')'*400;
RStdPrcY= rms(Ry,'omitnan')'*400;

M = IF.medianFieldSource({'MAG_PSF'});

if (Args.closeall)
    close all;
end

figure;
semilogy(M,RStdPrcX,'.')
xlabel('I')
ylabel('rstd(Rx) [mas]')
title(Args.title)
if Args.PlotY
    figure;
    semilogy(M,RStdPrcY,'.')
    xlabel('I')
    ylabel('rstd(Ry) [mas]')
    title(Args.title)
end