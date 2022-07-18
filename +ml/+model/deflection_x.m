function dx = deflection_x(t,t0,thetaE,mus,u0)

    betaT = ml.model.u_t(t,thetaE,mus,u0,t0);
    betaxT = ml.model.u_tx(t,thetaE,mus,u0,t0);
    dx = (betaxT./thetaE)./((betaT./thetaE).^2+2);
end