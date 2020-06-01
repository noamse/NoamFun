function [GAIAAstCat, ComData, FlagGAIA]= compare_astrometry_gaia(astcat,matchdata,varargin)
%{
Run the pipeline to comapre the pm and the location of the object to the
measures astrometry of GAIA

input: 
        astcat - AstCat struct array

        matchdata - the matched data structure, the output of 
                    Asmtry.match_mat


%}
DefV.use_rrms=true;
DefV.Units = 'rad';
DefV.UsePlxFit=false;
DefV.Nsigma=5;
DefV.JDcut= false;
DefV.JDforcut = [];

InPar = InArg.populate_keyval(DefV,varargin,mfilename);


JD2yr=1/365.25;
JD2000=2451545; %jd of 1.1.2000
RAD=180/pi;



ft = fittype('poly1');

for i=1:length(astcat)  
    if InPar.use_rrms
        astormetryrms(i)=   astcat(i).UserData.R.rrmsN;
    else
        astormetryrms(i) = 1;
    end
end                                                 


JD=matchdata.JD-JD2000;
JDgaia= 15.5- mean(JD(1,:)*JD2yr);
JD=JD*JD2yr - mean(JD(1,:)*JD2yr);

GAIAAstCat= Asmtry.compare_cat(matchdata,'Units',InPar.Units);
FlagGAIA = ~isnan(GAIAAstCat.Cat(:,GAIAAstCat.Col.RA));
if InPar.UsePlxFit
   FlagGAIA = FlagGAIA&  ~isnan(GAIAAstCat.Cat(:,GAIAAstCat.Col.Plx));
end
GAIAAstCat.Cat = GAIAAstCat.Cat (FlagGAIA ,:);
RA=matchdata.ALPHAWIN_J2000(FlagGAIA,:);
Dec=matchdata.DELTAWIN_J2000(FlagGAIA,:);

Nobject=length(RA(:,1));

if(InPar.UsePlxFit)
    [Coo,~] = celestial.SolarSys.calc_vsop87(matchdata.JD(1,:), 'Earth', 'e', 'E');
    X = Coo(1,:).';
    Y = Coo(2,:).';
    Z = Coo(3,:).';
end
for ObjectInd = 1:Nobject
    %JD(ObjectInd,:)=JD(ObjectInd,:)*JD2yr-15.5;
    CondForFit=~(isnan(RA(ObjectInd,:)));
    if InPar.JDcut
       CondForFit = CondForFit& ~((JD(ObjectInd,:)>InPar.JDforcut(1)) &(JD(ObjectInd,:)<InPar.JDforcut(2)));
    end
    plx =GAIAAstCat.Cat(ObjectInd,GAIAAstCat.Col.Plx)*pi/180/1000/3600;
%     alpha_plx_red= plx*(X(CondForFit).*sin(RA(ObjectInd,CondForFit)') - Y(CondForFit).*cos(RA(ObjectInd,CondForFit)'));
%     delta_plx_red= plx*(X(CondForFit).*cos(RA(ObjectInd,CondForFit)').*sin(Dec(ObjectInd,CondForFit)') ...
%     - Y(CondForFit).*sin(RA(ObjectInd,CondForFit)').*sin(Dec(ObjectInd,CondForFit)') - Z(CondForFit).*cos(Dec(ObjectInd,CondForFit)'));
    if(InPar.UsePlxFit)
        [alpha_plx_red,delta_plx_red] = Asmtry.plx_correction(Coo(:,CondForFit)',RA(ObjectInd,CondForFit)',Dec(ObjectInd,CondForFit)',plx);
    end
    
    w=1./(RAD*astormetryrms(CondForFit)).^2;
    Nepochforfit = numel((RA(ObjectInd,CondForFit)));
    if(InPar.UsePlxFit)

        radec_corr= [(RA(ObjectInd,CondForFit))'+alpha_plx_red ; Dec(ObjectInd,CondForFit)'+delta_plx_red];
    else 
        radec_corr= [(RA(ObjectInd,CondForFit))'; Dec(ObjectInd,CondForFit)'];
    end
    H = [ones(size(RA(ObjectInd,CondForFit)')) JD(ObjectInd,CondForFit)'];
    HH = sparse([H zeros(size(H)); zeros(size(H)) H]);
    ww= [w';w'];
    asmtry_sol(ObjectInd,:) = lscov(HH,radec_corr,ww);
    
    model_radec = HH*asmtry_sol(ObjectInd,:)';
    radev= abs(radec_corr(1:Nepochforfit) - model_radec(1:Nepochforfit));
    decdev= abs(radec_corr((Nepochforfit+1):end) - model_radec((Nepochforfit+1):end));
    
    flag_sigma_clip = radev< Util.stat.rstd(radev)*  InPar.Nsigma &decdev< Util.stat.rstd(decdev)*  InPar.Nsigma ;
    flag_sigma_clip = [flag_sigma_clip;flag_sigma_clip];
    HHclip = HH(flag_sigma_clip,:);
    asmtry_sol_clip(ObjectInd,:) = lscov(HHclip,radec_corr(flag_sigma_clip,:),ww(flag_sigma_clip));
    
    raind=  1:2; %position and proper motion
    decind= 3:4;

    N = numel(flag_sigma_clip);
    flagra = flag_sigma_clip(1:N/2);
    HHclip_ra= HH(flagra,raind);
    flagdec = N/2+1:N;
    HHclip_dec= HH(flagdec,decind);
    dof(ObjectInd) = sum(flag_sigma_clip)./2 -2;
    chi_ra(ObjectInd)= sum((( radec_corr(flagra,:)- HHclip_ra*asmtry_sol_clip(ObjectInd,raind)').^2).*ww(flagra));
    chi_dec(ObjectInd)= sum((( radec_corr(flagdec,:)- HHclip_dec*asmtry_sol_clip(ObjectInd,decind)').^2).*ww(flagdec));
    %ww(flagra) = ww(flagra).*chi_ra(ObjectInd)./dof(ObjectInd);
    %ww(flagdec) =  ww(flagdec).*chi_dec(ObjectInd)./dof(ObjectInd);
    % fit for acceleration model usning the same cliping flag
    H= [ones(size(RA(ObjectInd,CondForFit)')) JD(ObjectInd,CondForFit)' JD(ObjectInd,CondForFit)'.^2];
    HH = sparse([H zeros(size(H)); zeros(size(H)) H]);
    HHclip = HH(flag_sigma_clip,:);
    asmtry_sol_a_clip(ObjectInd,:) = lscov(HHclip,radec_corr(flag_sigma_clip,:),ww(flag_sigma_clip));
    %asmtry_sol_a_clip(ObjectInd,:) = lscov(HH,radec_corr,ww);
    %chi_sq_a(ObjectInd)= sum((( radec_corr(flag_sigma_clip,:)- HHclip*asmtry_sol_a_clip(ObjectInd,:)').^2).*ww(flag_sigma_clip));
    
    raind=  1:3; %position, proper motion and acceleration
    decind= 4:6;

    HHclip_ra= HH(flagra,raind);
    HHclip_dec= HH(flagdec,decind);

    chi_a_ra(ObjectInd)= sum((( radec_corr(flagra,:)- HHclip_ra*asmtry_sol_a_clip(ObjectInd,raind)').^2).*ww(flagra));
    chi_a_dec(ObjectInd)= sum((( radec_corr(flagdec,:)- HHclip_dec*asmtry_sol_a_clip(ObjectInd,decind)').^2).*ww(flagdec));
    %chi_sq_a(ObjectInd)= sum((( radec_corr- HH*asmtry_sol_a_clip(ObjectInd,:)').^2).*ww);
    
    
    
    % Calculate the Offset from the mean position, this will be used to the
    % PM and plx fit
    %{
    if strcmp(InPar.Units,'deg')
        OffRA=(RA(ObjectInd,CondForFit)-nanmean(RA(ObjectInd,CondForFit))).*cos(Dec(ObjectInd,CondForFit)./RAD);
        OffDec=Dec(ObjectInd,CondForFit)-nanmean(Dec(ObjectInd,CondForFit));
    
    else
        OffRA=(RA(ObjectInd,CondForFit)-nanmean(RA(ObjectInd,CondForFit)));%.*cos(Dec(ObjectInd,CondForFit));
        OffDec=Dec(ObjectInd,CondForFit)-nanmean(Dec(ObjectInd,CondForFit));
    end


    
     %fit for proper motion and position with a given parallax by GAIA
     if InPar.UsePlxFit 
            PMfit(ObjectInd)=Asmtry.fit_pm_parallax(matchdata.JD(ObjectInd,CondForFit)',OffRA',OffDec'...
                                         ,'ErrRA',astormetryrms(CondForFit),'ErrDec',astormetryrms(CondForFit),...
                                         'RA',(nanmean(RA(ObjectInd,CondForFit))),'Dec',nanmean(Dec(ObjectInd,CondForFit)),...
                                         'GivenPlx',GAIAAstCat.Cat(ObjectInd,GAIAAstCat.Col.Plx),'Plx_is_Given',true,...
                                         'RefEpoch', JD2000 + 15.5/JD2yr );
            PMfit(ObjectInd).Par(1) = (PMfit(ObjectInd).Par(1) + (nanmean(RA(ObjectInd,CondForFit))));
            PMfit(ObjectInd).Par(3) = PMfit(ObjectInd).Par(3) + (nanmean(Dec(ObjectInd,CondForFit)));
     else
         PMfit=[];
     end
     %}
     
end
ComData.asmtry_fit_clip = asmtry_sol_clip;
ComData.asmtry_fit = asmtry_sol_clip;
ComData.asmtry_fit_a_clip = asmtry_sol_a_clip;
ComData.dof = dof;
ComData.chi_ra = chi_ra;
ComData.chi_dec = chi_dec;
ComData.chi_a_ra = chi_a_ra;
ComData.chi_a_dec = chi_a_dec;
ComData.JDfit= JD(1,:);
ComData.JDgaia = JDgaia;
ComData.JDmean=mean(matchdata.JD(1,:));

%if ~isempty(PMfit)
%    ComData.PMfit=PMfit;
%end

%ComData.RAfit = RAfit';
%ComData.RAgof =RAGOF';
%ComData.Decfit = Decfit';
%ComData.Decgof =DecGOF';
%ComData.RAclipfit = RAfitclip;
%ComData.Decclipfit = Decfitclip;
%ComData.ParallaxFit= PMfit;


%{

GAIAAstCat =catsHTM.cone_search('GAIADR2',0,0,1,'OutType','astcat');
GAIAAstCat.Cat = [];
for ObjectInd=1:Nobject
    RAGAIAcone=nanmean(Alpha(ObjectInd,:));
    DecGAIAcone=nanmean(Delta(ObjectInd,:));
    [GAIACat,~,~]=catsHTM.cone_search('GAIADR2',RAGAIAcone,DecGAIAcone,1);
        
    Gaiasize=size(GAIACat);
        
    if ~(Gaiasize(1)== 1)
        GAIACat=nan(1,Gaiasize(2));
    end
    GAIAAstCat.Cat = [GAIAAstCat.Cat ; GAIACat];
    CondForFit=~(isnan(Alpha(ObjectInd,:))) ;
    JD(ObjectInd,:)=JD(ObjectInd,:)*JD2yr-15.5;
    
    w=astormetryrms(astormetryrms);
    RAfit(ObjectInd).fit=fit(JD(ObjectInd,CondForFit)' , (Alpha(ObjectInd,CondForFit))'  ,ft,     'Weight',   w);
    
end

ComData=[];

end

%}
%{
    ft = fittype('poly1');
    w=1./rmsfromastrometry(CondForFit);
    JD(ObjectInd,:)=JD(ObjectInd,:)*JD2yr-15.5;
    RAfit(ObjectInd).fit=fit(JD(ObjectInd,CondForFit)' , (Alpha(ObjectInd,CondForFit))'  ,ft,     'Weight',   w);
    Decfit(ObjectInd).fit=fit(JD(ObjectInd,CondForFit)' , (Delta(ObjectInd,CondForFit))'  ,ft,     'Weight',   w);
    
            
    OffRA=(Alpha(ObjectInd,CondForFit)-nanmean(Alpha(ObjectInd,CondForFit))).*cos(RAD*Delta(ObjectInd,CondForFit));
    OffDec=Delta(ObjectInd,CondForFit)-nanmean(Delta(ObjectInd,CondForFit));
    
            
    PMfit(ObjectInd)=Util.fit.fit_pm_parallax(matchdata.JD(ObjectInd,CondForFit)',OffRA',OffDec'...
                            ,'ErrRA',rmsfromastrometry(CondForFit),'ErrDec',rmsfromastrometry(CondForFit),...
                                        'RA',(Alpha(ObjectInd,CondForFit))','Dec',(Delta(ObjectInd,CondForFit))');
            
                                    
                                    
    RAPM(ObjectInd)     =   RAfit(ObjectInd).fit.p1*3600*1000*  nanmean(cos((pi/180)*Delta(ObjectInd,CondForFit))); %PM in mas/yr
    DecPM(ObjectInd)    =   Decfit(ObjectInd).fit.p1*3600*1000;
    RAzero(ObjectInd)   =   RAfit(ObjectInd).fit.p2*3600; %RA at gaia epoch [RA arsec];
    Deczero(ObjectInd)  =   Decfit(ObjectInd).fit.p2*3600; % Dec at gaia epoch [arcsec]
        
        
        
end


end
%}