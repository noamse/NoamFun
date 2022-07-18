function delta = deflection_2d(t,t0,thetaE,mus, u0)
    arguments
       t;
       t0=0;
       thetaE=1;
       mus=1;
       u0=0.2;
       
        
    end

    dx = ml.model.deflection_x(t,t0,thetaE,mus, u0);
    dy = ml.model.deflection_y(t,t0,thetaE,mus, u0);
    delta=  [dx,dy];

end
