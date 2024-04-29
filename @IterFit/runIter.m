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

%IF.epsS = cgs(Nss,bs,1e-7);
IF.epsS = bicg(Nss,bs,1e-8);

IF.epsSTrack{end+1} = IF.ParS;

updateParS(IF);



[Nee]       = calculateNee(IF);
[be]        = calculateBe(IF);


%IF.epsE = cgs(Nee,be,1e-7);
IF.epsE = bicg(Nee,be,1e-8);
updateParE(IF);
IF.epsETrack{end+1} = IF.ParE;
% if IF.Chromatic
%     [Ncc]       = calculateNcc(IF);
%     [bc]        = calculateBc(IF);
%     
%     IF.epsC = bicg(Ncc,bc,1e-7);
% 
%     IF.epsCTrack{end+1} = IF.ParC;
%     updateParC(IF);
% end

end