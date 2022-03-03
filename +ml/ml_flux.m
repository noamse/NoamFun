function F = ml_flux(t,par)

arguments 
    t;
    par = [0,10,0.1,1,1e-8]; % [t0,tE,u0,fsource,fbaseline] 
    
    
end
F = par(5)*ml.ml_magnification(t,par);


end