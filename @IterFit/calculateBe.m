function Be = calculateBe(IF,Args)
arguments
    IF;
    Args.Chromatic = false;
end

%[Aex,Aey]   = IF.generateEpochDesignMat;

Aex = IF.AeX;
Aey = IF.AeY;

[Rx,Ry]     = IF.calculateResiduals;
Rx(isnan(Rx))= 0;
Ry(isnan(Ry))= 0;
%Ws = calculateWs(IF);
Ws= calculateWes(IF);
Ws = median(Ws,1,'omitnan');
% if IF.Chromatic
%     Be = [];
%     pa = IF.getTimeSeriesField(1,{'pa'});
%     
%     for Iep=1:IF.Nepoch
%         AexC=Aex;
%         AeyC=Aey;
%         
%         if isnan(pa(Iep))
%             AexC(:,7) = Aex(:,7).*0;
%             AeyC(:,8) = Aey(:,8).*0;    
%         else
%             %AexC(:,7) = -Aex(:,7).*sin(pa(Iep)) + Aey(:,8).*cos(pa(Iep));
%             %AexC(:,8) = zeros(size(AexC(:,8)));
%             AexC(:,7) = Aex(:,7).*sin(pa(Iep));
%             AeyC(:,8) = Aey(:,8).*cos(pa(Iep));
%         end
%         Be = [Be;reshape(((Rx(Iep,:).*Ws)*AexC + (Ry(Iep,:).*Ws)*AeyC)' ,[],1)];
%         %Bee(:,:,Iep)= Bee(:,:,Iep) + ((Rx.*Ws)*Aex + (Ry.*Ws)*Aey)';
%     end
% else
Be = reshape(((Rx.*Ws)*Aex + (Ry.*Ws)*Aey)' ,[],1);
% end
    
end
    



%{
if IF.Chromatic
    %Be = zeros(IF.Nepoch.*numel(IF.ParE(:,1)),1);
    Be = [];
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
        Be= [Be;reshape(AexC'*(Rx(Iep,:)'.*Ws) + AeyC'*(Ry(Iep,:)'.*Ws) ,[],1)];
    end
else
%}

%Be= [Be;reshape(AexC'*(Rx(Iep,:)'.*Ws) + AeyC'*(Ry(Iep,:)'.*Ws) ,[],1)];

%end



