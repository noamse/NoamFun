function [Obj,CelestialCoo,Matched] = readCatsPath(TargetPath)



[Obj,CelestialCoo,Matched]= ml.util.loadAstCatMatch(TargetPath);
% Remove bad airmass, false fit and duplicate time.
[~, ~, ic] = unique(Obj.JD, 'stable');  % ia: indices of first occurrences
counts = accumarray(ic,1);
isUnique = counts(ic) == 1;
FlagSeczAM = median(Obj.Data.secz,2,'omitnan')<1.6 & isUnique ;
%flagMag = Obj.medianFieldSource({'MAG_PSF'})<17.5;
%Obj.Data=ml.util.flag_struct_field(Obj.Data,flagMag,'FlagByCol',true);
%Matched.Catalog = Matched.Catalog(flagMag,:); 
Obj.Data=ml.util.flag_struct_field(Obj.Data,FlagSeczAM,'FlagByCol',false);
Obj.JD = Obj.JD(FlagSeczAM);
FlagPix = Obj.Data.Yphase==-0.5|Obj.Data.Xphase==-0.5;
Obj.Data.X(FlagPix) = nan; Obj.Data.Y(FlagPix) = nan;
%Obj.Data.X = -Obj.Data.X;
end