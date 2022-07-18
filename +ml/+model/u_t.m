function u = u_t(t,thetaE,mus, u0,t0)


u = sqrt(u0.^2+((t-t0).*mus).^2);




end