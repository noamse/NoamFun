function astcat = open_directory_astrometry(Directory,varargin)

DefV.FlagMag = true;
DefV.MagColCell = 'MagG';
DefV.MagHigh = 19;
DefV.MagLow = 12;
DefV.UsedOnly = true;
DefV.NewUnitsAstCat=[];
InPar = InArg.populate_keyval(DefV,varargin,mfilename);

%call -  astcat = Asmtry.open_directory_astrometry(Directory)
astcat = Asmtry.open_directory_astcat('Directory',Directory,'NewUnitsAstCat',InPar.NewUnitsAstCat);
astcat = Asmtry.clear_failure(astcat);
if InPar.UsedOnly 
    astcat = Asmtry.get_astrometry_res(astcat,'FlagMag',true,'MagLow',InPar.MagLow,'MagHigh',InPar.MagHigh);
end

end