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

%IF.epsS = cgs(Nss,bs,1e-7);






[Nss]       = calculateNss(IF);
[bs]        = calculateBs(IF);
[IF.epsS,~] = bicg(Nss,bs,1e-9,100);
updateParS(IF);
IF.epsSTrack{end+1} = IF.ParS;


 [Nee]       = calculateNee(IF);
 [be]        = calculateBe(IF);
 [IF.epsE,~]= bicg(Nee,be,1e-9,100);
 updateParE(IF);
 IF.epsETrack{end+1} = IF.ParE;


if IF.HALat
%     [Ncc]       = calculateNcc(IF);
%     [bc]        = calculateBc(IF);
%     
%     [IF.epsC,~]= bicg(Ncc,bc,1e-7);
%
%     IF.epsCTrack{end+1} = IF.ParC;
%     updateParC(IF);
      % [Nhalat]    = calculateNhalat(IF);
      % [Bhalat]    = calculateBhalat(IF);
      % [IF.epsHalat,~]= bicg(Nhalat,Bhalat,1e-7);
      % updateParHalat(IF);
      % IF.epsHalatTrack{end+1} = IF.ParC;
      [Nhalat]    = calculateNhalatBins(IF);
      [Bhalat]    = calculateBhalatBins(IF);
      [IF.epsHalat,~]= bicg(Nhalat,Bhalat,1e-8,100);
      updateParHalatBins(IF);
end

updateRMSTrack(IF);
% if IF.AnnualEffect
%     [Naa]       = calculateNaa(IF);
%     [ba]        = calculateBa(IF);
%     [IF.epsA,~] = bicg(Naa,ba,1e-8);
%     updateParAnnual(IF);
%     IF.epsATrack{end+1} = IF.ParA;
% end
% if IF.PixPhase
%       [Npix]    = calculateNpix(IF);
%       [Bpix]    = calculateBpix(IF);
%       [IF.epsPix,~]= bicg(Npix,Bpix,1e-8);
%       updateParPix(IF);
% 
% 
% end