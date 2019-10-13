function [GAIAcat, data,comp,astcat,FlagGAIA]= full_comp(Directory,varargin)

DefV.Survey ='PTF';
DefV.SearchRadius= 0.5;
DefV.ApperaFactor=0.95;
DefV.MagLow=12;
DefV.MagHigh = 19;
DefV.Inst_Radial=true;
DefV.UsedOnly= false;
DefV.UsePlxFit = false;
DefV.NewUnitsAstCat='rad';
DefV.Units='rad';
DefV.Colls2return={'JD','XWIN_IMAGE','YWIN_IMAGE','MAG_PSF','ALPHAWIN_J2000','DELTAWIN_J2000'};

InPar = InArg.populate_keyval(DefV,varargin,mfilename);


astcat = Asmtry.open_directory_astrometry(Directory,'UsedOnly',InPar.UsedOnly,'FlagMag',true,'MagLow',InPar.MagLow,'MagHigh',InPar.MagHigh,'NewUnitsAstCat',InPar.NewUnitsAstCat);


[data,~]= Asmtry.match_mat(astcat,'match_SearchRadius',InPar.SearchRadius,'Survey',InPar.Survey,...
    'ApperaFactor',InPar.ApperaFactor,'Colls2return',InPar.Colls2return,'Units',InPar.Units);



[GAIAcat, comp,FlagGAIA]   = Asmtry.compare_astrometry_gaia(astcat,data,'UsePlxFit',InPar.UsePlxFit);
end
