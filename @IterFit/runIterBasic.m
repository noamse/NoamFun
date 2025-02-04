function runIterBasic(IF,Args)

arguments
    IF;
    Args.Chromatic =false;
end


%IF.epsSTrack = {}; IF.epsETrack={};

%[IF.ParS]      = IF.initiateParS;
%[IF.ParE]      = initiateParE(IF);
%IF.epsSTrack{end+1} = IF.ParS;
%IF.epsETrack{end+1} = IF.ParE;

%IF.epsS = cgs(Nss,bs,1e-7);



[Nee]       = calculateNee(IF);
[be]        = calculateBe(IF);
[IF.epsE,~]= bicg(Nee,be,1e-8);
updateParE(IF);
IF.epsETrack{end+1} = IF.ParE;



[Nss]       = calculateNss(IF);
[bs]        = calculateBs(IF);
[IF.epsS,~] = bicg(Nss,bs,1e-8);
updateParS(IF);
IF.epsSTrack{end+1} = IF.ParS;



end