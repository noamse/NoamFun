function Naa = calculateNaa(IF)


Baa = zeros([numel(IF.ParA(:,1)),numel(IF.ParA(:,1)),IF.Nsrc]);


[Aax,Aay]   = generateAnnualDesignMat(IF);
Wes = calculateWes(IF);
for Isrc = 1:IF.Nsrc
     W = Wes(:,Isrc); 
     Baa(:,:,Isrc)= Baa(:,:,Isrc) + (Aax'*(Aax.*W) + Aay'*(Aay.*W));

end

Naa = sparse(Baa(:,:,1));

for Iblk = 2:numel(Baa(1,1,:)); Naa = blkdiag(Naa,Baa(:,:,Iblk));end

end