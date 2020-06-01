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
    color=abs(color-nanmedian(color));
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
    Cat(i).rms_alpha_np = rms(alpha- InputCat(:,Cat(i).Col.ALPHAWIN_J2000));
    Cat(i).rms_delta_np = rms(delta- InputCat(:,Cat(i).Col.DELTAWIN_J2000));

    [parallalpha,~,~,S1]=    lscov(H(flag,:),resalpha(flag));
    [paralldelta,~,~,S2] =    lscov(H(flag,:),resdelta(flag));
     
    alpha_corr = InputCat(:,Cat(i).Col.ALPHAWIN_J2000) + H*parallalpha; 
    delta_corr = InputCat(:,Cat(i).Col.DELTAWIN_J2000) + H*paralldelta; 
    Cat(i).rms_alpha_p = rms(alpha- alpha_corr);
    Cat(i).rms_delta_p = rms(delta- delta_corr);

    
    InputCat(:,Cat(i).Col.DELTAWIN_J2000) =delta_corr;
    InputCat(:,Cat(i).Col.ALPHAWIN_J2000) =alpha_corr;
    
    
    astcatchrom(i).Cat=InputCat;
    
    Cat(i).PAcorrPar=[parallalpha paralldelta];

end

