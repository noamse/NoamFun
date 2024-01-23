function Wes = calculateWes(IF)
[Rx,Ry]     = calculateResiduals(IF);
R = sqrt(Rx.^2 + Ry.^2);

try
    G = ones(size(R));
    G(isnan(R)) = 0;
    % Check for outliers in each row (source)
    G(isoutlier(Rx,2)|isoutlier(Ry,2))=0;
    NumNansEpoch = sum(isnan(sqrt(Rx.^2 + Ry.^2)));
    MedNans = mean(NumNansEpoch);
    
    FWHM= IF.Data.fwhm(:,1);
    [N,Bins] = histcounts(FWHM);
    [~,Ibins] = max(N);
    ModeFWHM = Bins(Ibins);
    Ffwhm = ones(numel(FWHM),1);
    Ffwhm(FWHM>ModeFWHM) = (ModeFWHM./FWHM(FWHM>ModeFWHM)).^(1/2);
    
        
    Fnull = ones(numel(NumNansEpoch),1);
    Fnull(NumNansEpoch>MedNans) =(MedNans./NumNansEpoch(NumNansEpoch>MedNans)).^(1/2);
    if IF.Chromatic
        pa = IF.getTimeSeriesField(1,{'pa'});
        Fnull(isnan(pa))=0;
        %Fnull(
    end
    M = IF.medianFieldSource({'MAG_PSF'});
    RStdPrcX= tools.math.stat.rstd(Rx')'*0.4*1000;
    RStdPrcY= tools.math.stat.rstd(Ry')'*0.4*1000;
    
    CsecSin = IF.Data.C.*IF.Data.secz.*sin(IF.Data.pa);
    CsecCos= IF.Data.C.*IF.Data.secz.*cos(IF.Data.pa);
    FCsec = ones(size(G));
    FCsec(abs(CsecSin)'>0.7)= (0.7./CsecSin(abs(CsecSin)'>0.7)).^2;
    
    Delta = sqrt(RStdPrcX.^2 + RStdPrcY.^2);
    B = timeSeries.bin.binningFast([M, Delta], 0.5,[NaN NaN],{'MidBin', @nanmedian, @tools.math.stat.rstd,@numel});
    SigmaS = interp1(B(:,1),B(:,2),M ,'linear','extrap');
    SigmaS(SigmaS==0)=Inf;
    if IF.Chromatic
        Wes =G'.* Fnull.*Ffwhm .* G'.*1./(SigmaS').^2 .*FCsec ;
    else
        Wes =G'.* Fnull.*Ffwhm .* G'.*1./(SigmaS').^2;
    end
    
catch
    Wes = ones(size(R'));
    
end





