function Nee = calculateNee(IF,Args)

arguments
    IF;
    Args.Chromatic = false;
end


Bee = zeros([numel(IF.ParE(:,1)),numel(IF.ParE(:,1)),IF.Nepoch]);

W = calculateWs(IF);

%[Aex,Aey] = IF.generateEpochDesignMat;
Aex = IF.AeX;
Aey = IF.AeY;

if Args.Chromatic
    pa = IF.getTimeSeriesField(1,{'pa'});
    
    for Iep=1:IF.Nepoch
        AexC=Aex;
        AeyC=Aey;
        if isnan(pa(Iep))
            AexC(:,7) = Aex(:,7).*0;
            AeyC(:,8) = Aey(:,8).*0;    
        else
            AexC(:,7) = Aex(:,7).*cos(pa(Iep));
            AeyC(:,8) = Aey(:,8).*sin(pa(Iep));
        end
        Bee(:,:,Iep)= Bee(:,:,Iep) + (AexC'.*W)*AexC + (AeyC'.*W)*AeyC;
    end
else
    for Iep=1:IF.Nepoch
        Bee(:,:,Iep)= Bee(:,:,Iep) + (Aex'.*W)*Aex + (Aey'.*W)*Aey;
    end
end


Nee = sparse(Bee(:,:,1));

for Iblk = 2:numel(Bee(1,1,:)); Nee = blkdiag(Nee,Bee(:,:,Iblk));end

end
