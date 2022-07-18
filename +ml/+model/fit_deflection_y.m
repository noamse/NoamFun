function res = fit_deflection_y(t,Y,p0,varargin)
% Fit for "y" astrometric deflection. The function fit the astrometric
% deflection in the axis perpendicular to the proper motion.
%
%
% Input: 
%         - A vector contains of time
%         - A column vector of the Y position.
%         - A vector of initial guess (taken from photometry):
%           [t0,thetaE,mus,u0,x0,cos(alpha)]          
%         - 



func_min= @(par) sum((Y - par(6).*ml.model.deflection_y(t,par(1),par(2),par(3),par(4))+par(5)).^2);
[res,fval,exitflag,output] = fminsearch(func_min,p0);

end