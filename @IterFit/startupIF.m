function startupIF(IF)
arguments
    IF;
end
IF.epsSTrack = {}; IF.epsETrack={};

[IF.ParS]      = IF.initiateParS;
%[IF.ParE]      = IF.initiateParE('Chromatic',IF.Chromatic);
[IF.ParE]      = IF.initiateParE;
[IF.ParC]      = IF.initiateParC;
[IF.ParHalat]      = IF.initiateParHalat;
[IF.ParPix]      = IF.initiateParPix;
[IF.ParA]      = IF.initiateParAnnual;
IF.epsSTrack{1} = IF.ParS;
IF.epsETrack{1} = IF.ParE;
IF.epsCTrack{1} = IF.ParC;
[PlxX,PlxY] = calculatePlxTerms(IF,'Coo',IF.CelestialCoo);
IF.PlxTerms = [PlxX,PlxY];
end