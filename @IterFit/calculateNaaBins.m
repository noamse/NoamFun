function Naa = calculateNaaBins(IF,Args)


arguments
    IF;
    Args.a=1;
end


[~,~,binC] = generateBins(IF,'CBinWidth',0.25);
% split to bins, keep indices


[AaX,AaY] = generateAnnualDesignMat(IF);

[Rx,Ry]     = IF.calculateResiduals;
Rx(isnan(Rx))= 0;
Ry(isnan(Ry))= 0;
Wes = calculateWes(IF);

%Bhalat = reshape(AhaX'*(Rx.*Wes) + AhaY'*(Ry.*Wes) ,[],1);
binCUq=unique(binC(binC~=0));
Baa = zeros(numel(AaX(1,:)),numel(AaX(1,:)),numel(binCUq));
for IcBin = 1:numel(binCUq)
    FlagC = binCUq(IcBin) == binC;
    W = sum(Wes(:,FlagC),2);
    Baa(:,:,IcBin)= Baa(:,:,IcBin) + (AaX'*(AaX.*W) + AaY'*(AaY.*W));

end

Naa= sparse(Baa(:,:,1));

for Iblk = 2:numel(Baa(1,1,:)); Naa = blkdiag(Naa,Baa(:,:,Iblk));end

end