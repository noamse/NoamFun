function [fnu,nu] = ABMag2fluxdensity(mag,lambda,S,Teff,varargin)
% Lambda in angs


fbroad = ut.ABMag2flux(mag,lambda,S);




Lam = lambda.*1e-8;
kB = constant.kB;
c=constant.c;
h = constant.h;
fbb =2.*pi.*h.*c.^2.*Lam.^(-5) ./ (exp(h.*c./(Lam.*kB.*Teff)) - 1); %[erg/sec/cm^2/cm(lambda)]
fbb = fbb *1e-8;    %[erg/sec/cm^2/angs(lambda)]


alpha = fbroad.*trapz(lambda,S.*c*1e8./lambda)./trapz(lambda,fbb.*S.*lambda);

[maxval,indmax]=max(((lambda).^2).*fbb.*S);
fnu = alpha.*maxval./(c*1e8);

nu = c./lambda(indmax)  * 1e8;