function BaBins = calculateBaBins(IF,Args)


arguments
    IF;
    Args.Nbins = 10;
end
% change to BaBins




%Npar*Nbins

[~,~,binC] = generateBins(IF,'CBinWidth',0.25);
% split to bins, keep indices 


[AaX,AaY] = generateAnnualDesignMat(IF);

[Rx,Ry]     = IF.calculateResiduals;
Rx(isnan(Rx))= 0;
Ry(isnan(Ry))= 0;
Wes = calculateWes(IF);

%Ba = reshape(AhaX'*(Rx.*Wes) + AhaY'*(Ry.*Wes) ,[],1);
binCUq=unique(binC(binC~=0));
%BaBins = zeros(numel(AhaX(1,:)),numel(binCUq));
BaBins=[];

for Ic = 1:numel(binCUq)
    FlagC= binC == binCUq(Ic);
    RxTmp = Rx(:,FlagC);
    RyTmp = Ry(:,FlagC);
    WesTmp = Wes(:,FlagC);
    BaBins = [BaBins ; reshape(AaX'*(sum(RxTmp.*WesTmp,2)) + AaY'*(sum(RyTmp.*WesTmp,2)) ,[],1)];

end
end