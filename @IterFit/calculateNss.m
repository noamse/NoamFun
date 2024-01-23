function Nss = calculateNss(IF)


Bss = zeros([numel(IF.ParS(:,1)),numel(IF.ParS(:,1)),IF.Nsrc]);

%[Ax,Ay] = IF.generateSourceDesignMat;
Ax = IF.AsX;
Ay = IF.AsY;

Wes = calculateWes(IF);
for Isrc = 1:IF.Nsrc
     W = Wes(:,Isrc); 
     Bss(:,:,Isrc)= Bss(:,:,Isrc) + (Ax'*(Ax.*W) + Ay'*(Ay.*W));

end

Nss = sparse(Bss(:,:,1));

for Iblk = 2:numel(Bss(1,1,:)); Nss = blkdiag(Nss,Bss(:,:,Iblk));end

end