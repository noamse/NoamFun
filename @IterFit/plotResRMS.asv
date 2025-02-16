function [RStdPrcX,RStdPrcY,M,RstdPrc ] = plotResRMS(IF,Args)

arguments
    IF;
    Args.closeall = false;
    Args.title = '';
    Args.PlotY= true;
    Args.Plot2D = true;
end
% [Rx,Ry] = IF.calculateResiduals;
% Wes=  IF.calculateWes;
% Wes=median(Wes,2);
% Wes = Wes/max(Wes);
% FlagW = ones(size(Wes));%Wes>0.8;
% FlagOut = ~(isoutlier(Rx,1) | isoutlier(Ry,1)| isoutlier(sqrt(Ry.^2 + Rx.^2),1));
% Flag = logical(FlagOut.*FlagW);
% Flag =FlagOut;g
% Rx(~Flag)=nan;
% Ry(~Flag)=nan;
% RStdPrcX= rms(Rx,'omitnan')'*400;
% RStdPrcY= rms(Ry,'omitnan')'*400;
[RStdPrcX,RStdPrcY] = IF.calculateRstd;

M = IF.medianFieldSource({'MAG_PSF'});

if (Args.closeall)
    close all;
end

figure;
semilogy(M,RStdPrcX,'.','Color',[0.5,0.2,0.8],'MarkerSize',18)
xlabel('I')
ylabel('rms(Rx) [mas]')
title(Args.title)
if Args.PlotY
    figure;
    semilogy(M,RStdPrcY,'.','Color',[0.5,0.2,0.8],'MarkerSize',18)
    xlabel('I')
    ylabel('rms(Ry) [mas]')
    title(Args.title)
end


if Args.Plot2D 
    figure;
    RstdPrc = sqrt(RStdPrcY.^2 +RStdPrcX.^2);
    semilogy(M,RstdPrc  ,'.','Color',[0.5,0.2,0.8],'MarkerSize',18)
    xlabel('I')
    ylabel('rms(R) [mas]')
    title(Args.title)
end