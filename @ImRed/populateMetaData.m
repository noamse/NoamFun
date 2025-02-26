function populateMetaData(self,Cat,Im,Args)
    arguments
    self;
    Cat;
    Im;
    Args.KeyNameJD  = {'JD','JDMID'};
    Args.PSFKbestfitPar = [];
    
    end

    if Cat.isemptyCatalog
        Cat.JD = Im.HeaderData.getVal(Args.KeyNameJD);
        return
    end
    Cat.insertCol(Im.PSFData.fwhm*ones(size(Cat.getCol(1))),1,'fwhm');
    Lat = convert.dms2angle(Im.HeaderData.Key.LATITUDE,'rad');
    secz = str2double(Im.HeaderData.Key.SECZ);
    Alt = str2double(Im.HeaderData.Key.ALT)/180*pi;
    HA = convert.hour_str2frac(Im.HeaderData.Key.HA)*2*pi;
    Dec = convert.dms2angle(Im.HeaderData.Key.DEC);
    cospa = cos(Dec).*sin(Lat) - sin(Dec).*cos(Lat).*cos(HA);
    sinpa = sin(HA).*cos(Lat);
    %pa=atan2(sinpa,cospa);
    
    pa = atan(sin(HA)./(tan(Lat).*cos(Dec) - sin(Dec).*cos(HA)));
    DeltaPSFXY = Im.PSFData.moment2.X - Im.PSFData.moment2.Y;
    if ~isempty(Args.PSFKbestfitPar)
        Cat.UserData = Args.PSFKbestfitPar;
    end
    try
        CCDTEMP = str2double(Im.HeaderData.Key.CCDTEMP);
        FAFOCUS = str2double(Im.HeaderData.Key.FAFOCUS); % 
        FATILTNS = str2double(Im.HeaderData.Key.FATILTNS); %Focus Tilt NS Offset Angle
        FATILTEW = str2double(Im.HeaderData.Key.FATILTEW); % Focus Tilt EW Offset Angle
        EXPTIME  = (Im.HeaderData.Key.EXPTIME); 
        PixelPhaseX = mod(Cat.getCol('X'),1)-0.5;
        PixelPhaseY = mod(Cat.getCol('Y'),1)-0.5;
    catch 
        CCDTEMP =0;FAFOCUS =0;FATILTNS = 0; FATILTEW=0;EXPTIME=0;

    end
    

    try
        PixelPhaseX = mod(Cat.getCol('X'),1)-0.5;
        PixelPhaseY = mod(Cat.getCol('Y'),1)-0.5;
    catch
        PixelPhaseX = 10;
        PixelPhaseY = 10;
    end
    
    Cat.insertCol(pa*ones(size(Cat.getCol(1))),1,'pa');
    Cat.insertCol(secz*ones(size(Cat.getCol(1))),1,'secz');
    Cat.insertCol(Alt*ones(size(Cat.getCol(1))),1,'alt');
    Cat.insertCol(HA*ones(size(Cat.getCol(1))),1,'ha');
    Cat.insertCol(DeltaPSFXY *ones(size(Cat.getCol(1))),1,'DeltaPSFXY');

    Cat.insertCol(CCDTEMP*ones(size(Cat.getCol(1))),1,'CCDTEMP');
    Cat.insertCol(FAFOCUS*ones(size(Cat.getCol(1))),1,'FAFOCUS');
    Cat.insertCol(FATILTNS*ones(size(Cat.getCol(1))),1,'FATILTNS');
    Cat.insertCol(FATILTEW*ones(size(Cat.getCol(1))),1,'FATILTEW');
    Cat.insertCol(EXPTIME*ones(size(Cat.getCol(1))),1,'EXPTIME');
    Cat.insertCol(PixelPhaseX,1,'Xphase');
    Cat.insertCol(PixelPhaseY,1,'Yphase');
    %Cat.insertCol(double(Res.ConvergeFlag'),1,'Convg_flag');
    Cat.JD = Im.julday;







end



        
    