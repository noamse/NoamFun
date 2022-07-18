function dy = deflection_y(t,t0,thetaE,mus, beta0)

    betaT = ml.model.u_t(t,thetaE,mus,beta0,t0);
    betayT = ml.model.u_ty(t,thetaE,mus,beta0,t0);
    dy = (betayT./thetaE)./((betaT./thetaE).^2+2);
end