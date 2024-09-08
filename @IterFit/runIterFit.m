function IF = runIterFit(Obj,Args)

arguments
    Obj
    Args.Plx = false;
    Args.Chromatic =false;
    Args.HALat = false;
    Args.CelestialCoo = [];
    Args.UseWeights = true;
    Args.NiterNoWeights = 3;
    Args.NiterWeights = 3;
    Args.ChromaicHighOrder=true;
end


clear IF;
IF = IterFit(Obj.copy());
%IF = IterFit(ObjChrom.copy());
IF.Plx = Args.Plx; IF.Chromatic =Args.Chromatic; 
IF.HALat=Args.HALat; IF.ChromaicHighOrder = Args.ChromaicHighOrder;
IF.CelestialCoo = Args.CelestialCoo; IF.startupIF;
IF.UseWeights = false;
for I =1:Args.NiterNoWeights
    IF.runIter;
end

IF.UseWeights = Args.UseWeights;
for I =1:Args.NiterWeights
    IF.runIter;
end




