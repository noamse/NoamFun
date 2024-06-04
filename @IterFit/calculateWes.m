function Wes = calculateWes(IF)
[Rx,Ry]     = calculateResiduals(IF);
R = sqrt(Rx.^2 + Ry.^2);
if ~IF.UseWeights
    Wes =ones(size(Rx));
    return
end

if IF.newWeights
    
    try
        G = ones(size(R));
        G(isnan(R)) = 0;
        % Check for outliers in each row (source)
        G(isoutlier(Rx,1)|isoutlier(Ry,1))=0;
        NumNansEpoch = sum(isnan(sqrt(Rx.^2 + Ry.^2)),2);
        MedNans = mean(NumNansEpoch);
        R = sqrt(Rx.^2+Ry.^2);
        FlagOut = isoutlier(R);
        M = IF.medianFieldSource({'MAG_PSF'});
        Sigmase= ones(size(R));
        B = timeSeries.bin.binning([M, ones(size(M))], 0.5,[NaN NaN],{'MidBin', @nanmedian, @tools.math.stat.rstd,@numel,'StartBin','EndBin'});
        [~,~,bin] = histcounts(M,[B(:,5);B(end,6)]);
        for Ibin = 1:numel(unique(bin))
            Sigmase(:,bin==Ibin)= median(abs(R(:,bin==Ibin))*400,2,'omitnan').*ones(1,sum(bin==Ibin));
            
            
        end
        Wes = 1./Sigmase.^2;
        Wes(isnan(Wes))=0;
        Wes = Wes./sum(Wes(:));
        %Wes(FlagOut)=0;
    catch
        
        Wes = ones(size(R));
        disp('Unable to calculate weights');
    end

else
    %try
        G = ones(size(R));
        G(isnan(R)) = 0;
        % Check for outliers in each row (source)
        %G(isoutlier(Rx,1)|isoutlier(Ry,1))=0;
        NumNansEpoch = sum(isnan(sqrt(Rx.^2 + Ry.^2)),2);
        MedNans = mean(NumNansEpoch);
        
        FWHM= IF.Data.fwhm(:,1);
        %[N,Bins] = histcounts(FWHM);
        %[~,Ibins] = max(N);
        ModeFWHM = nanmedian(FWHM);
        Ffwhm = ones(numel(FWHM),1);
        Ffwhm(FWHM>ModeFWHM) = (ModeFWHM./FWHM(FWHM>ModeFWHM)).^(2);
        Ffwhm(isnan(FWHM))=0;
        
        Fnull = ones(numel(NumNansEpoch),1);
        Fnull(NumNansEpoch>MedNans) =(MedNans./NumNansEpoch(NumNansEpoch>MedNans)).^(1/2);
        
        if IF.Chromatic
            pa = IF.getTimeSeriesField(1,{'pa'});
            Fnull(isnan(pa))=0;
            %Fnull(
        end
        M = IF.medianFieldSource({'MAG_PSF'});
        
        
        RStdPrcX= tools.math.stat.rstd(Rx)'*0.4*1000;
        RStdPrcY= tools.math.stat.rstd(Ry)'*0.4*1000;
        % Calculate assymptotic RMS
        FlagMagAssymRMS = M<16 | M>14.5;
        ResAsyRMS = sqrt(Rx(:,FlagMagAssymRMS).^2+Ry(:,FlagMagAssymRMS).^2);
        SigmaAssymRMS = nanmedian(ResAsyRMS,2)*0.4*1000;
        WassymRMS = 1./SigmaAssymRMS.^2;
        WassymRMS(isnan(WassymRMS))=0;
        %CsecSin = IF.Data.C.*IF.Data.secz.*sin(IF.Data.pa);
        %CsecCos= IF.Data.C.*IF.Data.secz.*cos(IF.Data.pa);
        %FCsec = ones(size(G));
        %FCsec(abs(CsecSin)'>0.7)= (0.7./CsecSin(abs(CsecSin)'>0.7)).^2;
        
        Delta = sqrt(RStdPrcX.^2 + RStdPrcY.^2);
        B = timeSeries.bin.binning([M, Delta], 0.5,[NaN NaN],{'MidBin', @nanmedian, @tools.math.stat.rstd,@numel,'StartBin','EndBin'});
        [~,~,bin] = histcounts(M,[B(:,5);B(end,6)]);
        flagBin = ~(bin==0);
        FlagOutlier =ones(size(flagBin));
        FlagOutlier(flagBin) = Delta(flagBin)> (B(bin(flagBin),2)+2*B(bin(flagBin),3));
        FlagOutlier(~flagBin)=true;
        
        B = timeSeries.bin.binning([M(~FlagOutlier), Delta(~FlagOutlier)], 0.5,[NaN NaN],{'MidBin', @nanmedian, @tools.math.stat.rstd,@numel,'StartBin','EndBin'});
        WeightOutlier = ones(size(Delta'));
        WeightOutlier(logical(FlagOutlier)) = WeightOutlier(logical(FlagOutlier))/100;
        SigmaS = interp1(B(:,1),B(:,2),M ,'linear','extrap');
        SigmaS(isnan(SigmaS))=Inf;
        SigmaS(SigmaS==0)=Inf;
        WsigmaS = 1./(SigmaS').^2;
        Wes =G.* Fnull.*WassymRMS.*Ffwhm .* G.*WsigmaS .*WeightOutlier;
        %if IF.Chromatic
        %    Wes =G'.* Fnull.*Ffwhm .* G'.*1./(SigmaS').^2 .*FCsec ;
        %else
        %    Wes =G'.* Fnull.*Ffwhm .* G'.*1./(SigmaS').^2;
        %end
        
    %catch
    %    Wes = ones(size(R));
    %    disp('Unable to calculate weights');
        
    %end
     
    
end