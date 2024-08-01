function [Acx,Acy,Ac]   = generateChromaticDesign(IF,Args)

arguments
    IF;
    Args.Chromatic=true;
    
end



C = median(IF.Data.C)';
pa = IF.Data.pa(:,1);
ha = IF.Data.ha(:,1);
secz= IF.Data.secz(:,1);
Cparmat = ones(numel(pa),numel(C));

%Acx = Cparmat.*C'.*sin((pa)).*secz;
%Acy = Cparmat.*C'.*cos((pa)).*secz;
%Ac = Cparmat.*secz.*(cos(pa)+sin(pa));
Acx = Cparmat.*C'.*ha.*secz;
Acy = Cparmat.*C'.*ha.*secz;
Ac = Cparmat.*secz.*(cos(pa)+sin(pa));
%Ac = Cparmat.*secz;
%Acx = Cparmat.*C'.*sin(pa);
%Acy = Cparmat.*C'.*cos(pa);


Acy(isnan(Acy))=0;
Acx(isnan(Acx))=0;
Ac(isnan(Ac))=0;

%Acx = [C,zeros(size(C))];
%Acy = [zeros(size(C)),C];
% if IF.Chrom2D
%     Acx = [C,zeros(size(C))];
%     Acy = [zeros(size(C)),C];
% else
%     Acx = C;
%     Acy = C;
% end

%Acx=C;
%Acy=C;
