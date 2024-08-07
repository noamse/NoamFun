function Bc = calculateBc(IF,Args)
arguments
    IF;
    Args.Chromatic = false;
end

%[Aex,Aey]   = IF.generateEpochDesignMat;
%[Acx,Acy]   = generateChromDesignMat(IF);
[Acx,Acy,Ac]   = generateChromaticDesign(IF);
[Rx,Ry]     = IF.calculateResiduals;
Rx(isnan(Rx))= 0;
Ry(isnan(Ry))= 0;
%W = calculateWs(IF);
W = calculateWes(IF);


%Be = zeros(IF.Nepoch.*numel(IF.ParE(:,1)),1);
%Bc = zeros(IF.Nepoch.*numel(IF.ParC(:,1),1));
Bc = [];
%pa = IF.getTimeSeriesField(1,{'pa'});
%secz = IF.getTimeSeriesField(1,{'secz'});

for Iep=1:IF.Nepoch
    % AxC=Acx;
    % AyC=Acy;
    % 
    % if isnan(pa(Iep)) || isnan(secz(Iep))
    %     if IF.Chrom2D
    %         AxC(:,1) = AxC(:,1).*0;
    %         AyC(:,2) = AyC(:,2).*0;
    %     else
    %         AxC = AxC .*0;
    %         AyC = AyC .*0;
    %     end
    % 
    % else
    %     AxC= AxC.*cos(pa(Iep)).*secz(Iep);
    %     AyC= AyC.*sin(pa(Iep)).*secz(Iep);
    %     %AxC= AxC.*sin(pa(Iep)).*secz(Iep);
    %     %AyC= AyC.*cos(pa(Iep)).*secz(Iep);
    %     %AxC= AxC.*(pa(Iep));
    %     %AyC = AyC.*(pa(Iep));
    % end
    %Bc= [Bc;reshape(AxC'.*W(Iep,:)*(Rx(:,Iep)) + AyC'.*W(Iep,:)*(Ry(:,Iep)) ,[],1)];
    %Bc = [Bc;reshape(AxC(:,1)'.*W(Iep,:)*(Rx(:,Iep)) + AyC(:,2)'.*W(Iep,:)*(Ry(:,Iep)) ,[],1)];
    %Bc(Iep) = AxC(:,1)'.*W(Iep,:)*(Rx(:,Iep)) +  AyC(:,2)'.*W(Iep,:)*(Ry(:,Iep));
    %Bc(Iep) = AxC(:,1)'.*W(Iep,:)*(Rx(:,Iep)) +  AyC(:,2)'.*W(Iep,:)*(Ry(:,Iep));
    %Bc= [Bc;reshape(AxC'.*W(Iep,:)*(Rx(:,Iep)) ,[],1)];
    if IF.Chrom2D
        %Bc= [Bc;reshape(AyC'.*W(Iep,:)*(Ry(:,Iep)) ,[],1)];
        %Bc= [Bc;reshape(AxC'.*W(Iep,:)*(Rx(Iep,:)') +  AyC'.*W(Iep,:)*(Ry(Iep,:)') ,[],1)];
        %Bc= [Bc;reshape((Acx(Iep,:).*W(Iep,:))*(Rx(Iep,:)') +  (Acy(Iep,:).*W(Iep,:))*(Ry(Iep,:)') ,[],1)];
        Bc= [Bc;reshape([(Acx(Iep,:).*W(Iep,:))*(Rx(Iep,:)') +  (Acy(Iep,:).*W(Iep,:))*(Ry(Iep,:)'),(Ac(Iep,:).*W(Iep,:))*(Ry(Iep,:)')] ,[],1)];
    else
        Bc= [Bc;reshape((Acx(Iep,:).*W(Iep,:))*(Rx(Iep,:)') +  (Acy(Iep,:).*W(Iep,:))*(Ry(Iep,:)') ,[],1)];
        %
        %Bc= [Bc;reshape((Acx(Iep,:).*W(Iep,:))*(Rx(Iep,:)') +  (Acy(Iep,:).*W(Iep,:))*(Ry(Iep,:)'),[],1)];
    end
end





end