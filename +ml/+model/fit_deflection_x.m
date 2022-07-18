function res = fit_deflection_x(t,X,p0,varargin)
% Fit for "x" astrometric deflection. The function fit the astrometric
% deflection in the axis parallel to the proper motion.
%
%
% Input: 
%         - A vector contains of time
%         - A column vector of the X position.
%         - A vector of initial guess (taken from photometry):
%           [t0,thetaE,mus,u0,x0]          
%         - 



func_min= @(par) sum((X - ml.model.deflection_x(t,par(1),par(2),par(3),par(4))+par(5)).^2);
[res,fval,exitflag,output] = fminsearch(func_min,p0);

end