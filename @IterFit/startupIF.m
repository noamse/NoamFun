function startupIF(IF,Args)
arguments
    IF;
    Args.Coo =  [4.6273,-0.4646];
end
IF.epsSTrack = {}; IF.epsETrack={};

[IF.ParS]      = IF.initiateParS;
%[IF.ParE]      = IF.initiateParE('Chromatic',IF.Chromatic);
[IF.ParE]      = IF.initiateParE;
[IF.ParC]      = IF.initiateParC;
IF.epsSTrack{1} = IF.ParS;
IF.epsETrack{1} = IF.ParE;
IF.epsCTrack{1} = IF.ParC;
[PlxX,PlxY] = calculatePlxTerms(IF,'Coo',Args.Coo);
IF.PlxTerms = [PlxX,PlxY];
end