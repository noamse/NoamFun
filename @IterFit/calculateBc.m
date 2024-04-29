function Bc = calculateBc(IF,Args)
arguments
    IF;
    Args.Chromatic = false;
end

%[Aex,Aey]   = IF.generateEpochDesignMat;
[Acx,Acy]   = generateChromDesignMat(IF);

[Rx,Ry]     = IF.calculateResiduals;
Rx(isnan(Rx))= 0;
Ry(isnan(Ry))= 0;
%W = calculateWs(IF);
W = calculateWes(IF);


%Be = zeros(IF.Nepoch.*numel(IF.ParE(:,1)),1);
%Bc = zeros(IF.Nepoch.*numel(IF.ParC(:,1),1));
Bc = [];
pa = IF.getTimeSeriesField(1,{'pa'});
for Iep=1:IF.Nepoch
    AxC=Acx;
    AyC=Acy;
    if isnan(pa(Iep))
        AxC = AxC.*0;
        AyC = AyC.*0;
    else
        %AxC= AxC(:,1).*sin(pa(Iep));
        %AyC = AyC(:,1).*cos(pa(Iep));
        %AxC= AxC.*(pa(Iep));
        %AyC = AyC.*(pa(Iep));
    end
    %Bc= [Bc;reshape(AxC'.*W(Iep,:)*(Rx(:,Iep)) + AyC'.*W(Iep,:)*(Ry(:,Iep)) ,[],1)];
    %Bc = [Bc;reshape(AxC(:,1)'.*W(Iep,:)*(Rx(:,Iep)) + AyC(:,2)'.*W(Iep,:)*(Ry(:,Iep)) ,[],1)];
    %Bc(Iep) = AxC(:,1)'.*W(Iep,:)*(Rx(:,Iep)) +  AyC(:,2)'.*W(Iep,:)*(Ry(:,Iep));
    %Bc(Iep) = AxC(:,1)'.*W(Iep,:)*(Rx(:,Iep)) +  AyC(:,2)'.*W(Iep,:)*(Ry(:,Iep));
    %Bc= [Bc;reshape(AxC'.*W(Iep,:)*(Rx(:,Iep)) ,[],1)];
    if IF.Chrom2D
        %Bc= [Bc;reshape(AyC'.*W(Iep,:)*(Ry(:,Iep)) ,[],1)];
        Bc= [Bc;reshape(AxC'.*W(Iep,:)*(Rx(:,Iep)) +  AyC'.*W(Iep,:)*(Ry(:,Iep)) ,[],1)];
    else
        Bc= [Bc;reshape(AyC'.*W(Iep,:)*(Ry(:,Iep)) ,[],1)];
    end
end





end