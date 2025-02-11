function IF = runIterFit(Obj,Args)

arguments
    Obj
    Args.Plx = false;
    Args.Chromatic =false;
    Args.HALat = false;
    Args.PixPhase =false;
    Args.CelestialCoo = [];
    Args.UseWeights = true;
    Args.NiterNoWeights = 3;
    Args.NiterWeights = 3;
    Args.ChromaicHighOrder = true;
    Args.UsePixFlagSoruces=false;
    Args.PixFlagSorucesPtctile = 5;
    Args.AnnualEffect=false;
end


clear IF;
IF = IterFit(Obj.copy(),'CelestialCoo',Args.CelestialCoo,'Plx',Args.Plx,'Chromatic',Args.Chromatic,'ChromaicHighOrder',Args.ChromaicHighOrder,...
    'HALat',Args.HALat,'AnnualEffect',Args.AnnualEffect);
%IF = IterFit(ObjChrom.copy());
%IF.Plx = Args.Plx; IF.Chromatic =Args.Chromatic;  %IF.HALat=Args.HALat; IF.ChromaicHighOrder = Args.ChromaicHighOrder;
%IF.CelestialCoo = Args.CelestialCoo; 
% IF.startupIF; IF.AnnualEffect =  AnnualEffect;
IF.startupIF
IF.UseWeights = false;
for I =1:Args.NiterNoWeights
    %IF.runIterBasic;
    IF.runIter;
end

IF.UseWeights = Args.UseWeights;

for I =1:Args.NiterWeights
    %IF.runIterBasic;
    IF.runIter;
end





