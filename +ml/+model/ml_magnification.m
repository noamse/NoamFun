function flux = ml_magnification(t,t0,thetaE,mus, u0,fs,flux0)

arguments 
   t; 
   t0=0;
   thetaE=1;
   mus=1;
   u0=0.2;
   fs=1;
   flux0=1; 
end






u = ml.model.u_t(t,thetaE,mus, u0,t0);
A = fs.*(u.^2 + 2)./(u.*sqrt(u.^2+4)) + 1-fs;

flux = A.*flux0;




end