function f = VegaMag2flux(mag,lambda,T,varargin)
% Convert Vega mag into flux in [erg s^{-1} cm^{-2}]
% lambda in [A]
% T- filter transitivity


load('/home/noamse/matlab/MAAT/AstroSpec/vega_spec.mat')
InPar =inputParser;
addOptional(InPar ,'vega_spec',[]);
parse(InPar,varargin{:});

if isempty (InPar.Results.vega_spec)
    vega_spec=load('/home/noamse/matlab/MAAT/AstroSpec/vega_spec.mat');
    vega_spec=vega_spec.vega_spec;
end
vega_spec_intp = interp1(vega_spec(:,1),vega_spec(:,2),lambda);
flux_0_vega = trapz(lambda,vega_spec_intp.*T.*lambda);
f= flux_0_vega .*10.^(-0.4*mag);


end