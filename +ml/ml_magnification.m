function A = ml_magnification(t,par)

arguments 
   t; 
   par = [0,10,0.1,1]; %t0,tE,u0,fsource
    
end

[t0,mus,u0,fs]= deal(par(1),par(2),par(3),par(4));




u = sqrt(u0.^2+((t-t0).*mus).^2);
A = fs.*(u.^2 + 2)./(u.*sqrt(u.^2+4)) + 1-fs;






end