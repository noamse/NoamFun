function Wes = calculateWes(IF,Args)
arguments
    IF;
    Args.NormalizeWeights= true;
end
[Rx,Ry]     = calculateResiduals(IF);
R = sqrt(Rx.^2 + Ry.^2);
if ~IF.UseWeights
    Wes =ones(size(Rx));
    return
end


try
    G = ones(size(R));
    G(isnan(R)) = 0;
    % Check for outliers in each row (source)
    %G(isoutlier(Rx,1)|isoutlier(Ry,1))=0;
    OutLiers = isoutlier(Rx,'movmedian',50,"ThresholdFactor",1.5,'SamplePoints',IF.JD) ...
        | isoutlier(Ry,'movmedian',50,"ThresholdFactor",1.5,'SamplePoints',IF.JD)...
        | isoutlier(IF.Data.MAG_PSF,'movmedian',100,"ThresholdFactor",2,'SamplePoints',IF.JD);
    G(OutLiers )=0;
    Rx(~logical(G)) = nan;
    Ry(~logical(G)) = nan;
    NumNansEpoch = sum(isnan(sqrt(Rx.^2 + Ry.^2)),2);
    %MedNans = mean(NumNansEpoch);
    R = sqrt(Rx.^2+Ry.^2);
    %FlagOut = isoutlier(R);
    M = IF.medianFieldSource({'MAG_PSF'});
    Sigmase= ones(size(R));
    B = timeSeries.bin.binning([M, ones(size(M))], 0.5,[NaN NaN],{'MidBin', @nanmedian, @tools.math.stat.rstd,@numel,'StartBin','EndBin'});
    [~,~,bin] = histcounts(M,[B(:,5);B(end,6)]);
    %[~,~,binMat] = histcounts(,[B(:,5);B(end,6)]);
    for Ibin = 1:numel(unique(bin))
        %Sigmase(:,bin==Ibin)= median(abs(R(:,bin==Ibin)),2,'omitnan').*ones(1,sum(bin==Ibin));
        Sigmase(:,bin==Ibin)= mean(abs(R(:,bin==Ibin)),2,'omitnan').*ones(1,sum(bin==Ibin));
        

    end
    Sigmase(Sigmase<IF.minUncerntainty) = IF.minUncerntainty;
    Wes = 1./Sigmase.^2;
    Wes(isnan(Wes)|isnan(R))=0;
    if Args.NormalizeWeights
        Wes = Wes./sum(Wes(:));
    end
    %Wes(FlagOut)=0;
catch

    Wes = ones(size(R));
    disp('Unable to calculate weights');
end


