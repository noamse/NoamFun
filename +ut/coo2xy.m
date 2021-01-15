function XY = coo2xy(W, RA, Dec) 
% inversion of xy2coo by calling fminsearch and calculating the point nearest to RA/Dec
% Usage: xy = coo2xy(obj, RA, Dec)
% Use the GAIA match to transform the given RA/Dec into xy on the
% image plane.
% Specify coordinates as hexagesimal strings or numeric degrees,
% DO NOT GIVE RA AS NUMERIC HOURS, if you give it as numeric value,
% it must be in degrees!

if ischar(RA)
    RA = head.Ephemeris.hour2deg(RA);
end

if ischar(Dec)
    Dec = head.Ephemeris.sex2deg(Dec);
end
%xy2coofun= @(xy) xy2coo_sgr(obj,[xy(1) xy(2)]);
func = @(xy) sum(([RA Dec] - xy2coowarp(W,[xy(1) xy(2)]) ).^2); % minimization function

XY = fminsearch(func, W.WCS.CRPIX); % initial guess is middle of field

end

function radec=xy2coowarp(Wcs,xy)
[ra,dec]= xy2coo(Wcs,xy);
radec=[ra dec];

end
