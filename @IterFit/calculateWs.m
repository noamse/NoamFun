function Ws = calculateWs(IF)

[Rx,Ry]     = calculateResiduals(IF);
%R = sqrt(Rx.^2 + Ry.^2);
RStdPrcX= tools.math.stat.rstd(Rx')'*0.4*1000;
RStdPrcY= tools.math.stat.rstd(Ry')'*0.4*1000;

Delta = sqrt(RStdPrcX.^2 + RStdPrcY.^2);

try
    
    
    M = IF.medianFieldSource({'MAG_PSF'});
    B = timeSeries.bin.binningFast([M, Delta], 0.5,[NaN NaN],{'MidBin', @nanmedian, @tools.math.stat.rstd,@numel});
    SigmaS = interp1(B(:,1),B(:,2),M ,'linear','extrap');
    SigmaS(Sigma==0 | isnan(SigmaS)) = Inf;
    Ws = 1./(SigmaS').^2 ;
    
catch
    Ws = 1./Delta'.^2;
    %Ws = ones(1,IF.Nsrc);
end
