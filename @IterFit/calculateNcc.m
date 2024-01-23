function Ncc = calculateNcc(IF,Args)

arguments
    IF;
    Args.Chromatic = true;
end


%Bee = zeros([numel(IF.ParE(:,1)),numel(IF.ParE(:,1)),IF.Nepoch]);

Bcc = zeros([numel(IF.ParC(:,1)),numel(IF.ParC(:,1)),IF.Nepoch]);
%W = calculateWs(IF);
W = calculateWes(IF);

%[Aex,Aey] = IF.generateEpochDesignMat;
%Aex = IF.AeX;
%Aey = IF.AeY;
[Acx,Acy]   = generateChromDesignMat(IF);
pa = IF.getTimeSeriesField(1,{'pa'});
    
for Iep=1:IF.Nepoch
    AxC=Acx;
    AyC=Acy;
    if isnan(pa(Iep))
        AxC(:,1) = AxC(:,1).*0;
        AyC(:,2) = AyC(:,2).*0;
    else
        AxC(:,1) = AxC(:,1).*sin(pa(Iep));
        AyC(:,2) = AyC(:,2).*cos(pa(Iep));
        %AxC(:,1) = AxC(:,1).*(pa(Iep));
        %AyC(:,2) = AyC(:,2).*(pa(Iep));
    end
    Bcc(:,:,Iep)= Bcc(:,:,Iep) + (AxC'.*W(Iep,:))*AxC + (AyC'.*W(Iep,:))*AyC;
    
    
end


Ncc = sparse(Bcc(:,:,1));

for Iblk = 2:numel(Bcc(1,1,:)); Ncc = blkdiag(Ncc,Bcc(:,:,Iblk));end

end
