function [alpha_cor,delta_cor] = plx_correction(X,alpha,delta,plx)
% plx in radians
% X  -the barycenter rectangular corrdinates in au

alpha_cor = plx.*(X(:,1).*sin(alpha) - X(:,2).*cos(alpha));
delta_cor = plx.*(X(:,1).*cos(alpha).*sin(delta)- ...
    X(:,2).*sin(alpha).*sin(delta)- X(:,3).*cos(delta));


end
