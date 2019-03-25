function [Cat,astcatchrom]= pa_chromatic_corr(astcat,varargin)
%   Calculating the chromatic correction for an image, and return the
%   correction projected on the PA parallel and perpendicular axis.
%   Output : the coefficient 
%             respa=  parall(1)*Cat.color +parall(2)*airmass+ parall(3)
%   !!!     Look for angle units     !!!
Cat=chromatic_data_extractor(astcat);
Deg2Rad=pi/180;
arcsec2Rad=pi/180/3600;
DefV.UnitAngleOut='rad';

InPar = InArg.populate_keyval(DefV,varargin,mfilename);

astcatchrom=astcat;
for i=1:length(Cat)
    
    ROTMAT= [Cat(i).TranC.Par{1}{2} Cat(i).TranC.Par{1}{3}; Cat(i).TranC.Par{2}{2} Cat(i).TranC.Par{2}{3}];
    %Rotate the pixels to N  -  E    (North as the x axis, East as the y axis)
    resvec=[Cat(i).x_res Cat(i).y_res];
    resvec=ROTMAT*resvec'/norm(ROTMAT);
    resvec=resvec';
    %(E - N -> N - E)
    resvec= [resvec(:,2) resvec(:,1)];
    
    
    
    PA=Cat(i).PA;
    %Roatate the N-E axies by the parallactic to axis perpendicular and
    %parallel to the horizon
    q=PA;
    [respa, Rot]=Rotation2D(resvec,q);
    
    % respa are the residuals in the perpendicular and parallel direction
    % to the horizon respectivly
    
    
    %----   Create the x axis of the fit   ----
    
    %extract the Lat and Long and convert to Radians for AirMass
    %calculation
    Lat=Cat(i).Lat*Deg2Rad;
    %!!!!----Problem in the Longtitude reading - sometime positive----!!!!
    Long=-116.8599*Deg2Rad;
    [AirMass,AzAlt,HA]=celestial.coo.airmass(Cat(i).JD,Cat(i).RA*Deg2Rad,Cat(i).Dec*Deg2Rad,[Long Lat]);
    %extract the color of the reference catalog objects.
    color=Cat(i).color;
    
    constvec=ones(size(Cat(i).color));
    
    X=Cat(i).Cat(:,Cat(i).Col.XWIN_IMAGE);
    Y=Cat(i).Cat(:,Cat(i).Col.YWIN_IMAGE);
    
    %xparall=[color AirMass constvec];
    xparall=[color X.*color Y.*color AirMass constvec];
    
    %run the regression
    parall1 =    regress(respa(1,:)',xparall);
    % The fit for the parallel direction - debuging
    parall2 =    regress(respa(2,:)',xparall);

    
    %calculate the correction to the PA axises
    G_chrom= sum(parall1'.*xparall,2)/3600;
    corr_pa_hat=[G_chrom.*ones(length(q),1) zeros(length(q),1)];
    
    %corr_pa_hat=[G_perp_chrom.*ones(length(q),1) G_chrom.*ones(length(q),1)];
    
    % Rotate the correction of the PA axis to the Dec - RA. 
    correction_Dec_RA=Rotation2D(corr_pa_hat,-q);
    correction_Dec_RA=correction_Dec_RA';

    % apply the correction to the new catalog 
    Cat_chrom_corr=Cat(i).Cat;
    %correct the Dec location - minus sign since the declination is open
    %open from the meridian
    Cat_chrom_corr(:,Cat(i).Col.DELTAWIN_J2000)=Cat_chrom_corr(:,Cat(i).Col.DELTAWIN_J2000)- correction_Dec_RA(:,1);
    %correct the RA location 
    Cat_chrom_corr(:,Cat(i).Col.ALPHAWIN_J2000)=Cat_chrom_corr(:,Cat(i).Col.ALPHAWIN_J2000)+ ...
        (correction_Dec_RA(:,2));%.*cos(Deg2Rad*Cat_chrom_corr(:,Cat(i).Col.DELTAWIN_J2000));
    

    
    Cat(i).Cat_chrome_corr=Cat_chrom_corr;
    Cat(i).correction_Dec_RA=correction_Dec_RA;
    if isequal(InPar.UnitAngleOut,'rad')
           Cat_chrom_corr(:,Cat(i).Col.ALPHAWIN_J2000)=Cat_chrom_corr(:,Cat(i).Col.ALPHAWIN_J2000)*Deg2Rad;
           Cat_chrom_corr(:,Cat(i).Col.DELTAWIN_J2000)=Cat_chrom_corr(:,Cat(i).Col.DELTAWIN_J2000)*Deg2Rad;
    end
    astcatchrom(i).Cat=Cat_chrom_corr;
    %PAcorr1=    sum(parall1'.*xparall,2);
    %PAcorr2=    sum(parall2'.*xparall,2);
    Cat(i).PAres=respa;
    Cat(i).q=PA;
    Cat(i).PAcorrPar=[parall1 parall2];
end

