function [pos] = circle_pos(t,P,Inclination,Omega,OmP,A)
% Calcualte the cartesian vector of a objects in circular orbit.
% 
% input: 
%           t- time after periastron (t-T0);    Inclination,Omega,Omp - orbital angles. 
%           R - radius
%           
% output:
%           pos - cartesian X,Y,Z position in Radius units
%           
     Nu = mod(t./P,1).*2.*pi;
     [X,Y,Z] =BinAstr.trueanom2pos_sim(A,Nu,Omega,OmP,Inclination);
     pos = [X,Y,Z];

end
