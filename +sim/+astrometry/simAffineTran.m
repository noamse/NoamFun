function [X,Y,Pars] = simAffineTran(X,Y,Nepoch,Args)

arguments
   X;
   Y;
   Nepoch;
   Args.AffineRotationRange = [-0.01,0.01]/180*pi;
   Args.AffineTranslationRange = [-1,1]*1e-3;  
end


Pars = zeros(6,Nepoch); 
RotAngle= (rand(1,Nepoch) - 0.5 + mean(Args.AffineRotationRange)).*(max(Args.AffineRotationRange)-min(Args.AffineRotationRange));

Translation= (rand(2,Nepoch) - 0.5 + mean(Args.AffineTranslationRange)).*(max(Args.AffineTranslationRange)-min(Args.AffineTranslationRange));
Pars(1,:) = cos(RotAngle);
Pars(2,:) = sin(RotAngle);
Pars(3,:) = Translation(1,:); 
Pars(4,:) = -sin(RotAngle); 
Pars(5,:) = cos(RotAngle); 
Pars(6,:) = Translation(2,:); 




X = X.*Pars(1,:) + Y.*Pars(2,:) + ones(size(X)).*Pars(3,:);
Y = X.*Pars(4,:) + Y.*Pars(5,:) + ones(size(X)).*Pars(6,:);



end