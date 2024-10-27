function Nhalat = calculateNhalatBins(IF,Args)


arguments
    IF;
    Args.a=1;
end


[~,~,binC] = generateBins(IF);
% split to bins, keep indices


[AhaX,AhaY] = generateHALatDesignMat(IF);

[Rx,Ry]     = IF.calculateResiduals;
Rx(isnan(Rx))= 0;
Ry(isnan(Ry))= 0;
Wes = calculateWes(IF);

%Bhalat = reshape(AhaX'*(Rx.*Wes) + AhaY'*(Ry.*Wes) ,[],1);
binCUq=unique(binC(binC~=0));
Bha = zeros(numel(AhaX(1,:)),numel(AhaX(1,:)),numel(binCUq));
for IcBin = 1:numel(binCUq)
    FlagC = binCUq(IcBin) == binC;
    W = sum(Wes(:,FlagC),2);
    Bha(:,:,IcBin)= Bha(:,:,IcBin) + (AhaX'*(AhaX.*W) + AhaY'*(AhaY.*W));

end

Nhalat = sparse(Bha(:,:,1));

for Iblk = 2:numel(Bha(1,1,:)); Nhalat = blkdiag(Nhalat,Bha(:,:,Iblk));end

end