function Cat= chromatic_data_extractor(astcat,varargin)
%Create a structure with all the data needed to be extracted from the
%headers of the AstCat objects and slice the data by user criteria
%   input: 
%           
%           astcat - AstCat objects that created by astrometry.m output SIM
%           object, where Res is in is UserData field
%               !!!!THE ANGLES IN THE INPUT CATALOG ARE IN RADIAN!!!!
%           
%   
RAD=180/pi;
DefV.FlagName = 'N';
DefV.MagLow=5;
DefV.MagHigh=20;
DefV.PixScale = 1.01;
DefV.resUnits = 'deg';
DefV.Survey = 'PTF';
InPar = InArg.populate_keyval(DefV,varargin,mfilename);

if strcmp(InPar.Survey, 'ZTF')
    InPar.PixScale = 1.012;
end

Cat=struct.empty([length(astcat),0]) ;
%change from arcsec to pixel: 1.01 for DefV.Scale in astrometry
for i=1:length(astcat)
    
    Cat(i).ImSize=[cell2mat(astcat(i).getkey('NAXIS1')) cell2mat(astcat(i).getkey('NAXIS2'))];

    
    Res=astcat(i).UserData.R;
    if strcmp(InPar.FlagName,'N')
        FLAG= (InPar.MagLow<Res.RefMag(Res.FlagG))& (InPar.MagHigh>Res.RefMag(Res.FlagG)) ;
    
    else
        FLAG= (InPar.MagLow<Res.RefMag)& (InPar.MagHigh>Res.RefMag);
    end
    if (numel(FLAG)==numel(astcat(i).Cat(:,1)))
        Cat(i).Cat=astcat(i).Cat(FLAG,:);
    else
        Cat(i).Cat=astcat(i).Cat;
    end
    %For the case of catalog in radians
    %Save the angles in degrees
    if (isfield(Res,'Col'))
        RA=Cat(i).Cat(:,Res.Col.ALPHAWIN_J2000);
        Cat(i).RA=RA;
        Dec=Cat(i).Cat(:,Res.Col.DELTAWIN_J2000);
        Cat(i).Dec=Dec;

    %

    else
        RA=Cat(i).Cat(:,Res.AstCat.Col.ALPHAWIN_J2000);
        Cat(i).RA=RA;
        Dec=Cat(i).Cat(:,Res.AstCat.Col.DELTAWIN_J2000);
        Cat(i).Dec=Dec;

    end
    %
    Cat(i).Col=astcat(i).Col;
    Cat(i).ColCell=astcat(i).ColCell;
    
    
    %W=ClassWCS.populate(astcat(i));
    %Cat(i).WCS=W;
    Cat(i).TranC=Res.TranC;
    Cat(i).Az=cell2mat(astcat(i).getkey('AZIMUTH'));
    Cat(i).Al=cell2mat(astcat(i).getkey('ALTITUDE'));

    Cat(i).Lat=cell2mat(astcat(i).getkey('OBSLAT'));
    Cat(i).Lon=cell2mat(astcat(i).getkey('OBSLON'));
    if (strcmp(InPar.Survey,'ZTF')) 
        LSTdate=cell2mat(astcat(i).getkey('OBLST'));
        Cat(i).HA=cell2mat(astcat(i).getkey('HOURANGD'));
        Cat(i).Al=cell2mat(astcat(i).getkey('ELVATION'));
    else
        LSTdate=cell2mat(astcat(i).getkey('OBSLST'));
        Cat(i).HA=cell2mat(astcat(i).getkey('TELHA'));
        Cat(i).Al=cell2mat(astcat(i).getkey('ALTITUDE'));
    end
    
    Cat(i).LST=rem(datenum(LSTdate),1);
    Cat(i).telairmass=cell2mat(astcat(i).getkey('AIRMASS'));
    Cat(i).JD=cell2mat(astcat(i).getkey('OBSJD'));
    %Paralactic angle - get radian and return radian
    PA=celestial.coo.parallactic_angle([RA, Dec], Cat(i).LST, Cat(i).Lat./RAD) ;

    %Convert from radian to deg
    %PA=PA*RAD;
    Cat(i).PA=PA(:,1);
    [airmass,AzAlt,HA]=celestial.coo.airmass(Cat(i).JD*ones(size(RA)),RA,Dec,[Cat(i).Lon,Cat(i).Lat]./RAD);
    Cat(i).airmass=airmass;
    Cat(i).seeing = cell2mat(astcat(i).getkey('SEEING'));
    switch lower(InPar.resUnits)
        case 'deg'
            Cat(i).x_res=Res.ResidX(FLAG);
            Cat(i).y_res=Res.ResidY(FLAG);

        case 'rad'
            Cat(i).x_res=Res.ResidX(FLAG)/InPar.PixScale/RAD; 
            Cat(i).y_res=Res.ResidY(FLAG)/InPar.PixScale/RAD; 
            
        case 'arsec'
            Cat(i).x_res=Res.ResidX(FLAG)*3600/InPar.PixScale; 
            Cat(i).y_res=Res.ResidY(FLAG)*3600/InPar.PixScale; 
            
        otherwise
            error('Unknown OutCooUnits');
    end

    Cat(i).mag=Res.RefMag(FLAG);
    Cat(i).color=Res.RefColor(FLAG);
    Cat(i).FLAG=FLAG;
    Cat(i).AstCat = astcat(i);
end


