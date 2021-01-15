function [B,lambda]= BlackBody(T,varargin)
% Calcualte the Black Body radiation profile given a temperature [K] and scale.
% wavelength units [cm]

%[B,lambda] = phys.BlackBody(10000);


InPar =inputParser;
addOptional(InPar ,'Scale',1);
addOptional(InPar ,'lambda',[350:0.25:900].*1e-7);
parse(InPar,varargin{:});


lambda = InPar.Results.lambda;
h = constant.h;
c= constant.c;
kB= constant.kB;
B=  InPar.Results.Scale.* (2.*h.*c.^2./lambda.^5)./(exp((h.*c)./(lambda.*kB.*T))-1);


end 