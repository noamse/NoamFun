function plotResRMS(IF)

[Rx,Ry] = IF.calculateResiduals;
Wes=  IF.calculateWes;
Wes=median(Wes,2);
Wes = Wes/max(Wes);
FlagW = Wes>0.8;
FlagOut = ~(isoutlier(Rx,2) | isoutlier(Ry,2));
Flag = logical(FlagOut.*FlagW');
Flag =FlagOut;
Rx(~Flag)=nan;
Ry(~Flag)=nan;
RStdPrcX= rms(Rx','omitnan')'*400;
RStdPrcY= rms(Ry','omitnan')'*400;

M = IF.medianFieldSource({'MAG_PSF'});

figure;
semilogy(M,RStdPrcX,'.')
xlabel('I')
ylabel('rstd(Rx) [mas]')

figure;
semilogy(M,RStdPrcY,'.')
xlabel('I')
ylabel('rstd(Ry) [mas]')

end