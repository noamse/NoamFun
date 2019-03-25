function [astcatcut]= get_astrometry_res(astcat,varargin)
DefV.FlagName= 'IndexInSimN';

InPar = InArg.populate_keyval(DefV,varargin,mfilename);
astcatcut=astcat;
for i =1:numel(astcat)
    Flag=  astcat(i).UserData.R.(InPar.FlagName);
    astcatcut(i).Cat =astcat(i).Cat(Flag,:);
end



end
