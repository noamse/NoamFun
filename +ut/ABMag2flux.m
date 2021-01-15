function f = ABMag2flux(mag,lambda,S,varargin)
% Convert Vega mag into flux density in [erg cm^{-2} s^{-1} Hz^{-1}]
% lambda in [A]
% T- filter transitivity


load('/home/noamse/matlab/MAAT/AstroSpec/vega_spec.mat')
InPar =inputParser;
addOptional(InPar ,'Spec',[]);
parse(InPar,varargin{:});
InPar = InPar.Results;



Spec = (3.63110e-20)*ones(size(lambda));
f= 10.^(-0.4*(mag + 48.6)); % erg cm^{-2} s^{-1} Hz^{-1}



end