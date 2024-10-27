function BhalatBins = calculateBhalatBins(IF,Args)


arguments
    IF;
    Args.Nbins = 10;
end
% change to BhalatBins




%Npar*Nbins

[~,~,binC] = generateBins(IF);
% split to bins, keep indices 


[AhaX,AhaY] = generateHALatDesignMat(IF);

[Rx,Ry]     = IF.calculateResiduals;
Rx(isnan(Rx))= 0;
Ry(isnan(Ry))= 0;
Wes = calculateWes(IF);

%Bhalat = reshape(AhaX'*(Rx.*Wes) + AhaY'*(Ry.*Wes) ,[],1);
binCUq=unique(binC(binC~=0));
%BhalatBins = zeros(numel(AhaX(1,:)),numel(binCUq));
BhalatBins=[];

for Ic = 1:numel(binCUq)
    FlagC= binC == binCUq(Ic);
    RxTmp = Rx(:,FlagC);
    RyTmp = Ry(:,FlagC);
    WesTmp = Wes(:,FlagC);
    BhalatBins = [BhalatBins ; reshape(AhaX'*(sum(RxTmp.*WesTmp,2)) + AhaY'*(sum(RyTmp.*WesTmp,2)) ,[],1)];

end
end