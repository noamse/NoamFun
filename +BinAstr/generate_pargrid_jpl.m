function [JPL,ParGrid,ParGridCol]= generate_pargrid_jpl(numbermp,minPeriod,maxPeriod,OverSampling)


load('/home/noamse/astro/binary_asteroid/horizon2/data/GAIA/GAIADR2sso_obs.mat');
load('/home/noamse/astro/binary_asteroid/horizon2/data/GAIA/GAIADR2sso_orbitres.mat');
load('/home/noamse/astro/binary_asteroid/horizon2/data/GAIA/GAIADR2sso_orbit.mat');

AsteroidNumber=numbermp;
[MeanEpochLTC,MeanEpoch,MeanResAL,MeanResAL_err,MeanResAC,MeanScanPA,Lat,Long,distance] = ...
    BinAstr.readAstroidAstCat(AsteroidNumber,GAIADR2sso_obs,GAIADR2sso_orbit,GAIADR2sso_orbitres);

JPL.MeanEpochLTC =MeanEpochLTC;
JPL.MeanEpoch =MeanEpoch;
JPL.MeanResAL =MeanResAL;
JPL.MeanResAL_err =MeanResAL_err;
JPL.MeanResAL_err =MeanResAL_err;
JPL.MeanResAC=MeanResAC;
JPL.MeanScanPA = MeanScanPA;
JPL.Lat = Lat;
JPL.Long= Long;
JPL.distance=distance;



JPL.MeanEpoch_2014= MeanEpoch-convert.date2jd([1,1,2014]);
JPL.MeanEpochLTC_2014 = MeanEpochLTC-convert.date2jd([1,1,2014]);


ParGridCol.Omega =1 ; ParGridCol.OmP =2 ; ParGridCol.Inc =3 ; ParGridCol.T =4  ;  ParGridCol.P =5 ;  ParGridCol.A=6; ParGridCol.e=7;

%minPeriod=  50/24;
%maxPeriod=  150/24;
%OverSampling =8;
TimeSpan = 500;%1.8*365.25abs(max(JPL.MeanEpochLTC_2014)-min(JPL.MeanEpochLTC_2014));
%initializing the parameters grid for the degenarate case
ParGrid.Omega       = linspace(0,2*pi,20); %[rad]6
ParGrid.OmP         = 0.0; %[rad]
ParGrid.Inc         = linspace(0,pi,20); %[rad]  
ParGrid.T           = linspace(0,maxPeriod,20); %[day]
ParGrid.e           = 0;
ParGrid.f           = (1/maxPeriod) : 1/(OverSampling* TimeSpan) : 1/minPeriod; %[1/day]

ParGrid.P           = 1./ParGrid.f;
ParGrid.A           =  1/3600/1000/180*pi; % Wobble amplitude in  radians such = 1 mas @ 1 au



end