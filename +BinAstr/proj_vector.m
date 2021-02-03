function [xi,M] = proj_vector(MeanScanPA,Long,Lat)
%  Calculate the projection vector from the binary inertial frame to Gaia
%  observer
%  
% 
% 


u = [cos(Lat).*cos(Long),cos(Lat).*sin(Long),sin(Lat)];
n= [0,0,1]';
epsilon = 23.43657/180*pi;
M = [1,0,0;0,cos(epsilon),-sin(epsilon);0,sin(epsilon),cos(epsilon)];
U = M*u';
nperp = n-(n'*U).*U;
omg= cross(U,nperp);
xi = (cos(MeanScanPA').*nperp + sin(MeanScanPA').*omg)./(vecnorm(cos(MeanScanPA').*nperp + sin(MeanScanPA').*omg));


end
