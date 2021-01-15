function mag = flux2VegaMag(f,lambda,T,varargin)
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
mag= real(-2.5*log10(f./flux_0_vega));


end