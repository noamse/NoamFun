function Nss = calculateNssChrom(IF)


Bss = zeros([numel(IF.ParS(:,1)),numel(IF.ParS(:,1)),IF.Nsrc]);

[Ax,Ay] = IF.generateSourceDesignMatChrom;
Wes = calculateWes(IF);
C = IF.medianFieldSource({'C'});
for Isrc = 1:IF.Nsrc
     %Cvec = ones(size(IF.ParS(:,1)));
     %Cvec((end-1):end) = C(Isrc);
     AxS(:,[6,7]) = Ax(:,[6,7]).*C(Isrc);
     AyS(:,[6,7]) = Ay(:,[6,7]).*C(Isrc);
     W = Wes(:,Isrc); 
     Bss(:,:,Isrc)= Bss(:,:,Isrc) + (AxS'*(AxS.*W) + AyS'*(AyS.*W));

end

Nss = sparse(Bss(:,:,1));

for Iblk = 2:numel(Bss(1,1,:)); Nss = blkdiag(Nss,Bss(:,:,Iblk));end

end