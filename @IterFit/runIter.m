function runIter(IF,Args)

arguments
    IF;
    Args.Chromatic =false;
end


%IF.epsSTrack = {}; IF.epsETrack={};

%[IF.ParS]      = IF.initiateParS;
%[IF.ParE]      = initiateParE(IF);
%IF.epsSTrack{end+1} = IF.ParS;
%IF.epsETrack{end+1} = IF.ParE;
[Nss]       = calculateNss(IF);
[bs]        = calculateBs(IF);

IF.epsS = cgs(Nss,bs);

IF.epsSTrack{end+1} = IF.ParS;

updateParS(IF);



[Nee]       = calculateNee(IF);
[be]        = calculateBe(IF);


IF.epsE = cgs(Nee,be);

IF.epsETrack{end+1} = IF.ParE;
updateParE(IF);

if IF.Chromatic
    [Ncc]       = calculateNcc(IF);
    [bc]        = calculateBc(IF);
    
    IF.epsC = cgs(Ncc,bc);

    IF.epsCTrack{end+1} = IF.ParC;
    updateParC(IF);
end

end