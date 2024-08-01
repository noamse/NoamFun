function [Rx,Ry] = calculateResiduals(IF)


arguments
    IF;
end
%[Asx,Asy] = IF.generateSourceDesignMat;
Asx = IF.AsX;
Asy = IF.AsY;
%[Aex,Aey] = IF.generateEpochDesignMat;
Aex = IF.AeX;
Aey = IF.AeY;

if size(Aex,2)~= size(IF.ParE,1)
    error('Number of epochs parameter inconsistent');
end

% Rx = IF.Data.X - Asx*IF.ParS -(Aex*IF.ParE)' ;
% Ry = IF.Data.Y - Asy*IF.ParS -(Aey*IF.ParE)' ;
% 
% end

if IF.Chromatic
    pa = IF.getTimeSeriesField(1,{'pa'});
    secz = IF.getTimeSeriesField(1,{'secz'});
    [Acx,Acy]   = generateChromDesignMat(IF);
    ParC=IF.ParC;
    %ParCx = ParC(1,:).*sin(pa');
    %ParCy = ParC(1,:).*cos(pa');
    %ParC(isnan(ParC))=0;
    if IF.Chrom2D
    ParC(1,:) = ParC(1,:).*sin(pa').*secz';
    ParC(2,:) = ParC(2,:).*cos(pa').*secz';
    %ParC = ParC.*cos(pa');
    %ParC(isnan(ParC))=0;
    %Acx(:,1) = sin(pa(Iep)).*secz(Iep)
    Rx = IF.Data.X - Asx*IF.ParS -(Aex*IF.ParE)' - (Acx*ParC)' ;
    Ry = IF.Data.Y - Asy*IF.ParS -(Aey*IF.ParE)' - (Acy*ParC)';
    else
        ParCx = ParC.*sin(pa').*secz';
        ParCy = ParC.*cos(pa').*secz';
        Rx = IF.Data.X - Asx*IF.ParS -(Aex*IF.ParE)' - (Acx*ParCx)' ;
        Ry = IF.Data.Y - Asy*IF.ParS -(Aey*IF.ParE)' - (Acy*ParCy)';
    end
    
    %ParCx(isnan(ParCx))=0;
    %ParCy(isnan(ParCy))=0;
    %Rx = (IF.Data.X - Asx*IF.ParS -(Aex*IF.ParE)' + (Acx*ParCx)' )';
    %Ry = (IF.Data.Y - Asy*IF.ParS -(Aey*IF.ParE)' + (Acy*ParCy)')';
else
    if IF.HALat
        [AhalatX,AhalatY] = generateHALatDesignMat(IF);
        Rx = IF.Data.X - Asx*IF.ParS -(Aex*IF.ParE)' - AhalatX*IF.ParHalat;
        Ry = IF.Data.Y - Asy*IF.ParS -(Aey*IF.ParE)' - AhalatY*IF.ParHalat;
    else
        Rx = IF.Data.X - Asx*IF.ParS -(Aex*IF.ParE)' ;
        Ry = IF.Data.Y - Asy*IF.ParS -(Aey*IF.ParE)' ;
    end
end

%}