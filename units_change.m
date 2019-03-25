function astcat= units_change(astcat,varargin)
%{
change the untis of cols in astcat
%}

DefV.OutUnits = 'rad';
DefV.InUnits  = 'deg';
DefV.RAcol= 'ALPHAWIN_J2000';
DefV.Deccol= 'DELTAWIN_J2000';
InPar = InArg.populate_keyval(DefV,varargin,mfilename);

switch [InPar.OutUnits InPar.InUnits]
    case ['rad' 'deg']
        C = pi/180;
    case ['deg' 'rad']
        C= 180/pi;
end

for i= 1:numel(astcat)
    astcat(i).Cat(:,astcat(i).Col.(InPar.RAcol)) = astcat(i).Cat(:,astcat(i).Col.(InPar.RAcol)) * C;
    astcat(i).Cat(:,astcat(i).Col.(InPar.Deccol)) = astcat(i).Cat(:,astcat(i).Col.(InPar.Deccol)) * C;
        
end