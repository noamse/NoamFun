function [Cat,astcatchrom]= chromatic_corr_robust(astcat,varargin)
RAD= 180/pi;
Deg2Rad=pi/180;
DefV.UnitAngleOut='rad';
DefV.Survey='PTF';
DefV.MagLow = 12;
DefV.MagHigh = 19;
DefV.KeyRA              = {'RA','OBJRA','OBJRAD','CRVAL1'};
DefV.KeyDec             = {'DEC','OBJDEC','OBJDECD','CRVAL2'};
DefV.KeyEquinox         = {'EQUINOX'};
DefV.FlagName = 'N';

InPar = InArg.populate_keyval(DefV,varargin,mfilename);
Cat=Asmtry.chromatic_data_extractor(astcat,'Survey',InPar.Survey,'MagLow',InPar.MagLow,'MagHigh',InPar.MagHigh,'FlagName',InPar.FlagName);

astcatchrom=astcat;
for i=1:length(Cat)
    %ROTMAT= [Cat(i).TranC.Par{1}{2} Cat(i).TranC.Par{1}{3}; Cat(i).TranC.Par{2}{2} Cat(i).TranC.Par{2}{3}];
    %resvec=[Cat(i).x_res Cat(i).y_res];
    %Rmat = ROTMAT;
    %resvec=ROTMAT*resvec'/norm(ROTMAT);
    
    %resvec=resvec';
    q=Cat(i).PA;
    
    
    Ximg = Cat(i).Cat(:,Cat(i).Col.XWIN_IMAGE);
    Yimg = Cat(i).Cat(:,Cat(i).Col.YWIN_IMAGE);

    
    XCCD  = 2048 ; 
    YCCD  = 4096 ;
    arc2pix = 1/1.01;
    Xplane  =  -2*XCCD   - (35+37)*arc2pix - XCCD +Ximg;
    Yplane  =  39/2 * arc2pix  + YCCD - Yimg;
    R = sqrt(Xplane.^2+Yplane.^2);
    Phi = atan2(Yplane,Xplane);
    Lat=Cat(i).Lat*Deg2Rad;
    %!!!!----Problem in the Longtitude reading - sometime positive----!!!!
    Long=-116.8599*Deg2Rad;
    [AirMass,AzAlt,HA]=celestial.coo.airmass(Cat(i).JD,Cat(i).RA,Cat(i).Dec,[Long Lat]);

    color=Cat(i).color;
    flag = ~isnan(color);
    constvec=ones(size(Cat(i).color));
    %H=[constvec ,color,cos(q).*color ,sin(q).*color,cos(q).*color .^2 ,sin(q).*color .^2 ,cos(q).*color.^3,sin(q).*color .^3,AirMass];
    
    %H=[constvec ,color,cos(q).*color ,sin(q).*color,cos(q).*color .^2,sin(q).*color .^2,Yplane.*color,Xplane.*color ,Yplane.*color.^2,Xplane.*color.^2,AirMass];
    H=[constvec ,color,cos(q).*color ,sin(q).*color,cos(q).*color .^2,sin(q).*color .^2,...
        R.*color,R.*cos(Phi).*color ,R.*sin(Phi).*color ,R.*sin(Phi).*color.^2,R.*cos(Phi).*color.^2,AirMass];
    %H=[constvec ,color,cos(q).*color ,sin(q).*color,cos(q).*color .^2,sin(q).*color .^2,AirMass];
    H = normc(H);

    
    InputCat=Cat(i).Cat;
    Out     = getcoo(astcat(i),'KeyRA',InPar.KeyRA,'KeyDec',InPar.KeyDec,'KeyEquinox',InPar.KeyEquinox,'OutUnits','rad');
    Coo2000 = celestial.coo.coco([[Out.RA].',[Out.Dec].'],sprintf('j%06.1f',Out(1).Equinox),'j2000.0');
    RA  = Coo2000(:,1);
    Dec = Coo2000(:,2);
    
    %[X,Y] =celestial.proj.pr_gnomonic(InputCat(:,Cat(i).Col.ALPHAWIN_J2000),InputCat(:,Cat(i).Col.DELTAWIN_J2000),(RAD.*3600./1.01),[RA,Dec]);
    %X = X/(RAD.*3600./1.01)- resvec(:,1);
    %Y = Y/(RAD.*3600./1.01)- resvec(:,2);
  %{    
  
    SScale= RAD.*3600./1.01;
    [X,Y] =celestial.proj.pr_gnomonic(astcat(i).Cat(:,Cat(i).Col.ALPHAWIN_J2000),astcat(i).Cat(:,Cat(i).Col.DELTAWIN_J2000),SScale,[RA,Dec]);
    CD = [1 0; 0 1].*1.01./3600;
    MatchedCatCD = [CD*[X,Y]']';
    MatchedCatCD(:,1) = MatchedCatCD(:,1)+resvec(:,1);
    MatchedCatCD(:,2) = MatchedCatCD(:,2)+resvec(:,2);
    pix  = [inv(CD)*MatchedCatCD']'+ [2048, 4096]/2; 
    [B,I]=sort(pix(:,2));
  %}      

    
    R = astcat(i).UserData.R; 
    GAIAX = R.RefX(R.FlagG);
    GAIAY = R.RefY(R.FlagG);
    FlagMag = R.RefMag(R.FlagG)>InPar.MagLow& R.RefMag(R.FlagG)<InPar.MagHigh;
    GAIAX=GAIAX(FlagMag);
    GAIAY=GAIAY(FlagMag); 
    %{
%     CatX = R.CatX(R.FlagG);
%     CatY = R.CatY(R.FlagG);
%     CatX=CatX(FlagMag);
%     CatY=CatY(FlagMag); 
%     catplane= [CatX,CatY];
    
    
    pix=pix(I,:);
    
    pixgaia= [GAIAX,GAIAY];
    
    %[alpha,delta] = xy2coo(astcat(i),pix(:,1),pix(:,2));
    %[alpha,delta] = xy2coo(astcat(i),astcat(i).Cat(:,2),astcat(i).Cat(:,3));
    %[alpha,delta] =  [alpha,delta] = xy2coo(astcat(i),astcat(i).Cat(:,2),astcat(i).Cat(:,3));
    %}
    %Brings GAIA with a good approximation to the model...
    [alpha,delta] = celestial.proj.pr_ignomonic(GAIAX/RAD,GAIAY/RAD,[RA,Dec]);
    
    resalpha = alpha- InputCat(:,Cat(i).Col.ALPHAWIN_J2000);
    resdelta = delta - InputCat(:,Cat(i).Col.DELTAWIN_J2000);

    [parallalpha,~,~,S1]=    lscov(H(flag,:),resalpha(flag));
    [paralldelta,~,~,S2] =    lscov(H(flag,:),resdelta(flag));
     
    alpha_corr = InputCat(:,Cat(i).Col.ALPHAWIN_J2000) + H*parallalpha; 
    delta_corr = InputCat(:,Cat(i).Col.DELTAWIN_J2000) + H*paralldelta; 
    
    %[alpha,delta] = celestial.proj.pr_ignomonic(MatchedCatCD(:,1),MatchedCatCD(:,2),[RA,Dec]);
    %[alpha,delta] = celestial.proj.pr_ignomonic(GAIAX/RAD,GAIAY/RAD,[RA,Dec]);
    %[X,Y]=projection(Cat(i).AstCat,'itan',[astcat(i).Col.ALPHAWIN_J2000 astcat(i).Col.DELTAWIN_J2000],[RAD.*3600./1.01 RA Dec],'rad');
    
    InputCat(:,Cat(i).Col.DELTAWIN_J2000) =delta_corr;%nansum([InputCat(:,Cat(i).Col.DELTAWIN_J2000),resvec(:,2)],2);
    InputCat(:,Cat(i).Col.ALPHAWIN_J2000) =alpha_corr;%nansum([InputCat(:,Cat(i).Col.ALPHAWIN_J2000),resvec(:,1)],2);
    
%     InputCat(:,Cat(i).Col.DELTAWIN_J2000) =nansum([InputCat(:,Cat(i).Col.DELTAWIN_J2000),resvec(:,2)/180*pi],2);
%     InputCat(:,Cat(i).Col.ALPHAWIN_J2000) =nansum([InputCat(:,Cat(i).Col.ALPHAWIN_J2000),resvec(:,1)/180*pi],2);
    
    astcatchrom(i).Cat=InputCat;
    
    Cat(i).PAcorrPar=[parallalpha paralldelta];

end

