function [Mag,Flux]= initiateParPhot(SA,Args)

arguments
    SA;
    Args.A = 1;
    Args.ZP =25;
end

if isempty(SA.ZP)
    ZP=Args.ZP;
else
    ZP = SA.ZP;
end

Mag = (SA.MagRange(2)-SA.MagRange(1)).*rand(1,SA.NsrcIn) + SA.MagRange(1);
MagErr = normrnd(0,SA.MagStd,SA.NepochIn,SA.NsrcIn);
Mag = Mag + MagErr;

Flux = 10.^(-0.4.*(Mag-ZP));
