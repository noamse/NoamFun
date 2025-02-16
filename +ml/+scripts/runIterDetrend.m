function [IF,Obj] = runIterDetrend(Obj,Args)

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
    Args.NAnualIter = 3;
    Args.updateObj = false;
    Args.NIterPix = 4;
end


clear IF;
IF = IterFit(Obj.copy(),'CelestialCoo',Args.CelestialCoo,'Plx',false,'Chromatic',Args.Chromatic,'ChromaicHighOrder',Args.ChromaicHighOrder,...
    'HALat',Args.HALat,'AnnualEffect','AnnualEffect');
%IF = IterFit(ObjChrom.copy());
%IF.Plx = Args.Plx; IF.Chromatic =Args.Chromatic;  %IF.HALat=Args.HALat; IF.ChromaicHighOrder = Args.ChromaicHighOrder;
%IF.CelestialCoo = Args.CelestialCoo; 
% IF.startupIF; IF.AnnualEffect =  AnnualEffect;
IF.startupIF
IF.UseWeights = false;
for I =1:Args.NiterNoWeights
    IF.runIterBasic;
end

IF.UseWeights = Args.UseWeights;

%for I =1:Args.NiterWeights
%    IF.runIterBasic;
%end

for I =1:Args.NiterWeights
    IF.runIter;
end





 if IF.AnnualEffect
     
     for I=1:Args.NAnualIter 
        [Naa]       = calculateNaa(IF);
        [ba]        = calculateBa(IF);
        [IF.epsA,~] = bicg(Naa,ba,1e-8);
        [Aax,Aay]   = generateAnnualDesignMat(IF);
        updateParAnnual(IF);
        IF.Data.X = IF.Data.X - Aax*IF.ParA;
        IF.Data.Y = IF.Data.Y - Aay*IF.ParA;
        IF.ParA=IF.initiateParAnnual;
        %updateParAnnual(IF);
        %IF.epsATrack{end+1} = IF.ParA;
     end
 end





if Args.PixPhase
    for Iiter = 1:Args.NIterPix
        %[IF,Obj] = runIterativePixCorrection(IF,Obj);%,'NIterPix',Args.NIterPix,'NIterNoWeights',);
        [~,PixCorrX,PixCorrY]= ml.detrend.correctPixPhase(IF,Obj.copy());
        IF.Data.X(:) = IF.Data.X(:) - PixCorrX;    
        IF.Data.Y(:) = IF.Data.Y(:) - PixCorrY;
    end
  
end

if Args.Plx
    IF.Plx = true;
    IF.ParS = IF.initiateParS;

end
for I =1:Args.NiterWeights
    IF.runIterBasic;
end


if Args.updateObj 
    Obj.Data.X  =IF.Data.X;
    Obj.Data.Y = IF.Data.Y;
end