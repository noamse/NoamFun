function populateMetaData(self,Cat,Im,Args)
    arguments
    self;
    Cat;
    Im;
    Args.KeyNameJD  = {'JD','JDMID'};
    
    
    end

    if Cat.isemptyCatalog
        Cat.JD = Im.HeaderData.getVal(Args.KeyNameJD);
        return
    end
    Cat.insertCol(Im.PSFData.fwhm*ones(size(Cat.getCol(1))),1,'fwhm');
    Lat = convert.dms2angle(Im.HeaderData.Key.LATITUDE,'rad');
    secz = str2double(Im.HeaderData.Key.SECZ);
    HA = convert.hour_str2frac(Im.HeaderData.Key.HA)*2*pi;
    Dec = convert.dms2angle(Im.HeaderData.Key.DEC);
    cospa = cos(Dec).*sin(Lat) - sin(Dec).*cos(Lat).*cos(HA);
    sinpa = sin(HA).*cos(Lat);
    pa=atan2(sinpa,cospa);
    %pa = atan(sin(HA)./(tan(Lat).*cos(Dec) - sin(Dec).*cos(HA)));
    Cat.insertCol(pa*ones(size(Cat.getCol(1))),1,'pa');
    Cat.insertCol(secz*ones(size(Cat.getCol(1))),1,'secz');
    %Cat.insertCol(double(Res.ConvergeFlag'),1,'Convg_flag');
    Cat.JD = Im.julday;







end



        
    