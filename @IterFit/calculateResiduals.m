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

if IF.Chromatic
    pa = IF.getTimeSeriesField(1,{'pa'});
    [Acx,Acy]   = generateChromDesignMat(IF);
    ParC=IF.ParC;
    ParC(1,:) = ParC(1,:).*sin(pa');
    ParC(2,:) = ParC(2,:).*cos(pa');
    ParC(isnan(ParC))=0;
    Rx = (IF.Data.X - Asx*IF.ParS -(Aex*IF.ParE)' + (Acx*IF.ParC)' )';
    Ry = (IF.Data.Y - Asy*IF.ParS -(Aey*IF.ParE)' + (Acy*IF.ParC)')';
else
    Rx = (IF.Data.X - Asx*IF.ParS -(Aex*IF.ParE)' )';
    Ry = (IF.Data.Y - Asy*IF.ParS -(Aey*IF.ParE)' )';
end

end