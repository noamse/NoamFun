function [GAIAaxisCOL, Colmtag] = BinAstrResGAIA_Deg(ParGrid,MeanEpochLTC,MeanScanPA,distance,Long,Lat,ParGridCol)
%{
Calculate the COL residuals as seen by the GAIA along axis.
inputs:
       
   ParGrid -       vector of parameters for the simulated COL

   MeanEpochLTC-   light time corrected epoches [days]

   MeanScanPA -    GAIA's position angle for each epoch [rad]

   distance -      distances between the COM and GAIA's [au]

   Long,Lat -      Longtitude and Latitude [rad] 
                   ecliptic longitude and latitude of the 
                   target's apparent position


   ParGridCol -    struct with the parameters name as a field and the
                   values are the indexes in the ParGrid array.
%}

Epoch=MeanEpochLTC -ParGrid(ParGridCol.T);

[COLiner] =BinAstr.circle_pos(Epoch,ParGrid(ParGridCol.P),ParGrid(ParGridCol.Inc),ParGrid(ParGridCol.Omega),ParGrid(ParGridCol.OmP),ParGrid(ParGridCol.A));
%COLdiamater in [deg]
COLdiamater=atand(COLiner./distance);
%project the COL to Observer plane
Colmtag= BinAstr.Proj2Obs(COLdiamater,Long,Lat);
%[NorthPoleEclipticCoo]= celestial.coo.coco([0,pi/2],'j2000','e');
NorthPoleEclipticCoo=[1.570796326794897 1.161703527618819];

[~,PAEarth_ecliptic]=celestial.coo.sphere_dist_fast(Long,Lat,NorthPoleEclipticCoo(1),NorthPoleEclipticCoo(2));
%2d -> 1d projection for GAIA's along scan axis
%PA=PAEarth_ecliptic +MeanScanPA;
%GAIAaxisCOL= Colmtag(:,1).*sin(PA) + Colmtag(:,2).*cos(PA);

PA=PAEarth_ecliptic - MeanScanPA;
GAIAaxisCOL= Colmtag(:,1).*cos(PA+pi/2) + Colmtag(:,2).*sin(PA+pi/2);

end