function dRdxi = diffRes(SymModel,DPar)

dRdxi = -diff(SymModel,DPar);
