function [res] = fit_mag(t,flux,par0)

arguments
    t;
    flux;
    par0 = [nan,1,1, 0.2,1]; %t0,tE,mus,u0,fsource
    
end


if isnan(par0(1))
    par0(1)=median(t,'omitnan');
end


%[t0,thataE0,mus,u0,fs]= deal(par0(1),par0(2),par0(3),par0(4),par0(5));
m0=median(flux,'omitnan');
par0= [par0,m0];
w= flux;
fmin = @(par) sum(((flux-ml.model.ml_magnification(t,par(1),par(2),par(3),par(4),par(5),par(6))).^2).*w);
[res,fval,exitflag,output] = fminsearch(fmin,par0);

end