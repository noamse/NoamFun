function [RStdPrcX,RStdPrcY,M,RstdPrc ] = plotResRMS(IF,Args)

arguments
    IF;
    Args.closeall = false;
    Args.title = '';
    Args.Plot2D = false;
    Args.PlotCorr= true;    
    Args.XYtogether =false;
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
Rstd2D = sqrt(RStdPrcX.^2 + RStdPrcY.^2);

OutLiersRMSvsMag = ml.util.iterativeOutlierDetection(Rstd2D,M,10,'MoveMedianStep',0.5);
if (Args.closeall)
    close all;
end


if Args.XYtogether
    figure;
    semilogy(M(~OutLiersRMSvsMag),RStdPrcX(~OutLiersRMSvsMag),'.','Color',[0.5,0.2,0.8],'MarkerSize',18)
    hold on;
    semilogy(M(OutLiersRMSvsMag),RStdPrcX(OutLiersRMSvsMag),'*','Color',[0.71, 0.40, 0.11],'MarkerSize',18)
    xlabel('I [mag]')
    semilogy(M(~OutLiersRMSvsMag),RStdPrcY(~OutLiersRMSvsMag),'d','Color',[0.5,0.2,0.8],'MarkerSize',18)
    hold on;
    semilogy(M(OutLiersRMSvsMag),RStdPrcY(OutLiersRMSvsMag),'o','Color',[0.71, 0.40, 0.11],'MarkerSize',18)
    
else

    figure;
    semilogy(M(~OutLiersRMSvsMag),RStdPrcX(~OutLiersRMSvsMag),'.','Color',[0.5,0.2,0.8],'MarkerSize',18)
    hold on;
    semilogy(M(OutLiersRMSvsMag),RStdPrcX(OutLiersRMSvsMag),'*','Color',[0.71, 0.40, 0.11],'MarkerSize',18)
    xlabel('I [mag]')
    ylabel('rms(Rx) [mas]')
    title(Args.title)

    figure;
    semilogy(M(~OutLiersRMSvsMag),RStdPrcY(~OutLiersRMSvsMag),'.','Color',[0.5,0.2,0.8],'MarkerSize',18)
    hold on;
    semilogy(M(OutLiersRMSvsMag),RStdPrcY(OutLiersRMSvsMag),'*','Color',[0.71, 0.40, 0.11],'MarkerSize',18)
    xlabel('I [mag]')
    ylabel('rms(Ry) [mas]')
    title(Args.title)
end


if Args.Plot2D 
    figure;
    %RstdPrc = sqrt(RStdPrcY.^2 +RStdPrcX.^2);
    semilogy(M(~OutLiersRMSvsMag),Rstd2D(~OutLiersRMSvsMag)  ,'.','Color',[0.5,0.2,0.8],'MarkerSize',18)
    hold on;
    semilogy(M(OutLiersRMSvsMag),Rstd2D(OutLiersRMSvsMag)  ,'*','Color',[0.71, 0.40, 0.11],'MarkerSize',18)
    xlabel('I [mag]')
    ylabel('rms(R) [mas]')
    title(Args.title)
end
figure;

if Args.PlotCorr
    loglog(RStdPrcX(~OutLiersRMSvsMag),RStdPrcY(~OutLiersRMSvsMag),'.','Color',[0.5,0.2,0.8],'MarkerSize',18)
    hold on;
    loglog(RStdPrcX(OutLiersRMSvsMag),RStdPrcY(OutLiersRMSvsMag),'*','Color',[0.71, 0.40, 0.11],'MarkerSize',18)
    plot([min([RStdPrcX(:);RStdPrcX(:)]),max([RStdPrcX(:);RStdPrcX(:)])],[min([RStdPrcX(:);RStdPrcX(:)]),max([RStdPrcX(:);RStdPrcX(:)])]);
    xlabel('rms(Rx) [mas]')
    ylabel('rms(Ry) [mas]')
    %axis box;
end



