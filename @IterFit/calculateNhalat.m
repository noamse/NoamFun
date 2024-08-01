function Nhalat = calculateNhalat(IF)


Bha = zeros([numel(IF.ParHalat(:,1)),numel(IF.ParHalat(:,1)),IF.Nsrc]);

%[Ax,Ay] = IF.generateSourceDesignMat;
%Ax = IF.AsX;
%Ay = IF.AsY;

[AhaX,AhaY] = generateHALatDesignMat(IF);
Wes = calculateWes(IF);
for Isrc = 1:IF.Nsrc
     W = Wes(:,Isrc); 
     Bha(:,:,Isrc)= Bha(:,:,Isrc) + (AhaX'*(AhaX.*W) + AhaY'*(AhaY.*W));

end

Nhalat = sparse(Bha(:,:,1));

for Iblk = 2:numel(Bha(1,1,:)); Nhalat = blkdiag(Nhalat,Bha(:,:,Iblk));end

end