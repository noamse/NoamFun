function updateParHalatBins(IF)

[~,~,binC] = generateBins(IF);
binCUq=unique(binC(binC~=0));
NparsHalat = numel(IF.ParHalat(:,1));
epsReshape = reshape(IF.epsHalat,NparsHalat,[]);
for IcBin = 1:numel(binCUq)
    FlagC = binCUq(IcBin) == binC;
    
    IF.ParHalat(:,FlagC)= IF.ParHalat(:,FlagC)+ epsReshape(:,IcBin).*ones(size(IF.ParHalat(:,FlagC)));
end  