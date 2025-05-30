function [IF,Obj] = runIterDetrend(Obj,Args)

arguments
    Obj
    Args.IF = [];
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
    Args.NAnualIter = 2;
    Args.updateObj = true;
    Args.NIterPix = 2;
    Args.InitialXYGuess=[];
    Args.ContaminatingFlux = [];
    Args.FinalStep = false;
end



if isempty(Args.IF)
    
    IF = IterFit(Obj.copy(),'CelestialCoo',Args.CelestialCoo,'Plx',false,'Chromatic',Args.Chromatic,'ChromaicHighOrder',Args.ChromaicHighOrder,...
        'HALat',Args.HALat,'AnnualEffect',Args.AnnualEffect,'AffineNoOnes',false,'InitialXYGuess',Args.InitialXYGuess,'ContaminatingFlux',Args.ContaminatingFlux);
    %IF = IterFit(ObjChrom.copy());
    %IF.Plx = Args.Plx; IF.Chromatic =Args.Chromatic;  %IF.HALat=Args.HALat; IF.ChromaicHighOrder = Args.ChromaicHighOrder;
    %IF.CelestialCoo = Args.CelestialCoo;
    % IF.startupIF; IF.AnnualEffect =  AnnualEffect;
    IF.startupIF
    IF.UseWeights = false;
    for I =1:Args.NiterNoWeights
        IF.runIterBasic;
    end
    
else
    % In case we are in final iteration, we use IF given by the user, and
    % update the data from Obj.Data
    IF=Args.IF;
    IF.Data = Obj.Data;
end
IF.UseWeights = Args.UseWeights;

%for I =1:Args.NiterWeights
%    IF.runIterBasic;
%end

if Args.FinalStep
    IF.AnnualEffect=false;
    IF.PixPhase=false;
end
for I =1:Args.NiterWeights
    IF.runIter;
    if IF.AnnualEffect
        [Naa]       = calculateNaaBins(IF);
        [ba]        = calculateBaBins(IF);
        %[Naa]       = calculateNaa(IF);
        %[ba]        = calculateBa(IF);
        [IF.epsA,~] = bicg(Naa,ba,1e-8);
        [Aax,Aay]   = generateAnnualDesignMat(IF);
       
        updateParAnnualBins(IF);
        %updateParAnnual(IF);
        IF.epsATrack{end+1} = IF.ParA;
        IF.Data.X = IF.Data.X - Aax*IF.ParA;
        IF.Data.Y = IF.Data.Y - Aay*IF.ParA;
        

        IF.ParA=IF.initiateParAnnual;
        %updateParAnnualBins(IF);
        %updateParAnnual(IF);
    end
    if Args.PixPhase

        [~,PixCorrX,PixCorrY]= ml.detrend.correctPixPhase(IF,Obj.copy());
        [Rx,Ry] = IF.calculateResiduals;
        Wes = IF.calculateWes;
        %[PixCorrX,ParPixX, ~] = correct2DIntraPixelX(Rx(:), IF.Data.Xphase(:), IF.Data.Yphase(:),'Weights',Wes(:));
        %[PixCorrY,ParPixY, ~] = correct2DIntraPixelX(Ry(:), IF.Data.Xphase(:), IF.Data.Yphase(:),'Weights',Wes(:));
        %[PixCorrX,ParPixX, ~] = correct1DIntraPixelX(Rx(:), IF.Data.Xphase(:),'Weights',Wes(:));
        %[PixCorrY,ParPixY, ~] = correct1DIntraPixelX(Ry(:), IF.Data.Yphase(:),'Weights',Wes(:));
        %IF.epsPixTrack{end+1} = [ParPixX,ParPixY];
        IF.Data.X(:) = IF.Data.X(:) - PixCorrX;
        IF.Data.Y(:) = IF.Data.Y(:) - PixCorrY;
    end
end

if Args.Plx
   IF.Plx=true;
   ParS = expandParSPlx(IF);
   IF.ParS= ParS;
end
IF.runIter;



 % 
 % 
 % if IF.AnnualEffect
 % 
 %     for I=1:Args.NAnualIter 
 %        [Naa]       = calculateNaa(IF);
 %        [ba]        = calculateBa(IF);
 %        [IF.epsA,~] = bicg(Naa,ba,1e-8);
 %        [Aax,Aay]   = generateAnnualDesignMat(IF);
 %        updateParAnnual(IF);
 %        IF.Data.X = IF.Data.X - Aax*IF.ParA;
 %        IF.Data.Y = IF.Data.Y - Aay*IF.ParA;
 %        IF.ParA=IF.initiateParAnnual;
 %        %updateParAnnual(IF);
 %        %IF.epsATrack{end+1} = IF.ParA;
 %     end
 % end
% 
% 
% for I =1:2
%     IF.runIter;
% end
% 
% 
% 
% 
% 
% 
% 
% if Args.PixPhase
%     for Iiter = 1:Args.NIterPix
%         %[IF,Obj] = runIterativePixCorrection(IF,Obj);%,'NIterPix',Args.NIterPix,'NIterNoWeights',);
%         [~,PixCorrX,PixCorrY]= ml.detrend.correctPixPhase(IF,Obj.copy());
%         IF.Data.X(:) = IF.Data.X(:) - PixCorrX;    
%         IF.Data.Y(:) = IF.Data.Y(:) - PixCorrY;
%     end
% 
% end
% 



if Args.updateObj 
    Obj.Data.X  =IF.Data.X;
    Obj.Data.Y = IF.Data.Y;
end