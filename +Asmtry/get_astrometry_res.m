function [astcatcut]= get_astrometry_res(astcat,varargin)
DefV.FlagName= 'IndexInSimN';
DefV.FlagMag = true;
DefV.MagColCell = 'MagG';
DefV.MagHigh = 19;
DefV.MagLow = 12;
InPar = InArg.populate_keyval(DefV,varargin,mfilename);
astcatcut=astcat;
for i =1:numel(astcat)
    Flag=  astcat(i).UserData.R.(InPar.FlagName);
    astcatcut(i).Cat =astcat(i).Cat(Flag,:);
    astcatcut(i)= col_insert(astcatcut(i),astcat(i).UserData.R.RefMag(astcat(i).UserData.R.FlagG),numel(astcatcut(i).ColCell)+1,InPar.MagColCell);
    if InPar.FlagMag
        FlagMag = astcatcut(i).Cat(:,astcatcut(i).Col.(InPar.MagColCell))>InPar.MagLow & ...
            astcatcut(i).Cat(:,astcatcut(i).Col.(InPar.MagColCell))<InPar.MagHigh;
        astcatcut(i).Cat = astcatcut(i).Cat(FlagMag,:);
    end
end



end
