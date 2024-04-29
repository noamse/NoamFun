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

Rx = IF.Data.X - Asx*IF.ParS -(Aex*IF.ParE)' ;
Ry = IF.Data.Y - Asy*IF.ParS -(Aey*IF.ParE)' ;

end
%{
if IF.Chromatic
    pa = IF.getTimeSeriesField(1,{'pa'});
    [Acx,Acy]   = generateChromDesignMat(IF);
    ParC=IF.ParC;
    %ParCx = ParC(1,:).*sin(pa');
    %ParCy = ParC(1,:).*cos(pa');
    %ParC(isnan(ParC))=0;
    %ParC(1,:) = ParC(1,:).*sin(pa');
    %ParC(2,:) = ParC(2,:).*cos(pa');
    ParC = ParC.*cos(pa');
    ParC(isnan(ParC))=0;
    Rx = IF.Data.X - Asx*IF.ParS -(Aex*IF.ParE)' ;%+ (Acx*ParC)' )';
    Ry = IF.Data.Y - Asy*IF.ParS -(Aey*IF.ParE)' ;%+ (Acy*ParC)')';
    %ParCx(isnan(ParCx))=0;
    %ParCy(isnan(ParCy))=0;
    %Rx = (IF.Data.X - Asx*IF.ParS -(Aex*IF.ParE)' + (Acx*ParCx)' )';
    %Ry = (IF.Data.Y - Asy*IF.ParS -(Aey*IF.ParE)' + (Acy*ParCy)')';
else
    Rx = IF.Data.X - Asx*IF.ParS -(Aex*IF.ParE)' ;
    Ry = IF.Data.Y - Asy*IF.ParS -(Aey*IF.ParE)' ;
end

%}