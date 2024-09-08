function [ParE] = initiateParE(SA,Args)

arguments
    SA;
    Args.A = [];
    %Args.Nepoch;

end

ParE = zeros(6,SA.NepochIn); 
RotAngle= (rand(1,SA.NepochIn) - 0.5 + mean(SA.AffineRotationRange)).*(max(SA.AffineRotationRange)-min(SA.AffineRotationRange));

Translation= (rand(2,SA.NepochIn) - 0.5 + mean(SA.AffineTranslationRange )).*(max(SA.AffineTranslationRange )-min(SA.AffineTranslationRange ));
ParE(1,:) = cos(RotAngle);
ParE(2,:) = sin(RotAngle);
ParE(3,:) = Translation(1,:); 
ParE(4,:) = -sin(RotAngle); 
ParE(5,:) = cos(RotAngle); 
ParE(6,:) = Translation(2,:); 
end










