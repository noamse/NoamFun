function [RefCat,RefTab] = generateRefCat(SA,Args)

arguments
    SA;
    Args.A =1;
end


RefMag = SA.medianFieldSource({'MAG_PSF'});
Coo = SA.CelestialCoo * 180/pi.*ones(size(RefMag));
RefTab = [SA.ParS(1,:)',SA.ParS(2,:)',RefMag,Coo ];
RefCat = AstroCatalog({RefTab},'ColNames',{'X','Y','I','RA','Dec'});
RefCat.sortrows('Y');
%save([ImageTargetFolder,'RefCat.mat'],'RefCat');
