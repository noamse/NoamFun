function updateParAnnualBins(IF)

[~,~,binC] = generateBins(IF,'CBinWidth',0.25);
binCUq=unique(binC(binC~=0));
NparsA = numel(IF.ParA(:,1));
epsReshape = reshape(IF.epsA,NparsA,[]);
for IcBin = 1:numel(binCUq)
    FlagC = binCUq(IcBin) == binC;
    
    IF.ParA(:,FlagC)= IF.ParA(:,FlagC)+ epsReshape(:,IcBin).*ones(size(IF.ParA(:,FlagC)));
end  