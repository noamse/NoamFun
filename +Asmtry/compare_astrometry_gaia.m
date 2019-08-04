function [GAIAAstCat, ComData, FlagGAIA]= compare_astrometry_gaia(astcat,matchdata,varargin)
%{
Run the pipeline to comapre the pm and the location of the object to the
measures astrometry of GAIA

input: 
        astcat - AstCat struct array

        matchdata - the matched data structure, the output of 
                    Asmtry.match_mat


%}

DefV.Units = 'rad';
InPar = InArg.populate_keyval(DefV,varargin,mfilename);


JD2yr=1/365.25;
JD2000=2451545; %jd of 1.1.2000
RAD=pi/180;



ft = fittype('poly1');

for i=1:length(astcat)                         
    astormetryrms(i)=   astcat(i).UserData.R.rrmsN;
end                                                 


JD=matchdata.JD-JD2000;
GAIAAstCat= Asmtry.compare_cat(matchdata);
FlagGAIA = ~isnan(GAIAAstCat.Cat(:,GAIAAstCat.Col.RA));
GAIAAstCat.Cat = GAIAAstCat.Cat (FlagGAIA ,:);
RA=matchdata.ALPHAWIN_J2000(FlagGAIA,:);
Dec=matchdata.DELTAWIN_J2000(FlagGAIA,:);

Nobject=length(RA(:,1));
RAfit = [];
Decfit = [];

RAlscovfit = zeros(Nobject,2);
Declscovfit = zeros(Nobject,2);

RAfitclip =zeros(Nobject,2);
Decfitclip = zeros(Nobject,2);
for ObjectInd = 1:Nobject
    
    JD(ObjectInd,:)=JD(ObjectInd,:)*JD2yr-15.5;
    CondForFit=~(isnan(RA(ObjectInd,:)));
    w=1./(astormetryrms(CondForFit)).^2;
    RAfit(ObjectInd).fit=fit(JD(ObjectInd,CondForFit)' , (RA(ObjectInd,CondForFit))'  ,ft,     'Weight',   w);
    Decfit(ObjectInd).fit=fit(JD(ObjectInd,CondForFit)' , (Dec(ObjectInd,CondForFit))'  ,ft,     'Weight',   w);
    
    H = [ones(size(RA(ObjectInd,CondForFit)')) JD(ObjectInd,CondForFit)'];
    
    RAlscovfit(ObjectInd,:) = (lscov(H,RA(ObjectInd,CondForFit)',w))';
    Declscovfit(ObjectInd,:) = (lscov(H,Dec(ObjectInd,CondForFit)',w))';
    
    ModelRA  = H * RAlscovfit(ObjectInd,:)';
    ModelDec  = H * Declscovfit(ObjectInd,:)';
    
    RAdev= abs( ModelRA- RA(ObjectInd,CondForFit)');
    Decdev= abs( ModelRA- Dec(ObjectInd,CondForFit)');
    
    RASigmaClipingFlag  = stat.sigmaclip(RAdev,4);
    DecSigmaClipingFlag = stat.sigmaclip(Decdev,4);
    HsigRA = H(RASigmaClipingFlag,:);
    HsigDec = H(DecSigmaClipingFlag,:);
    RAclip= RA(ObjectInd,CondForFit)';
    RAclip= RAclip(RASigmaClipingFlag);
    
    RAfitclip(ObjectInd,:)  = lscov(HsigRA,RAclip,w(RASigmaClipingFlag));
    
    
    % Calculate the Offset from the mean position, this will be used to the
    % PM and plx fit
    if strcmp(InPar.Units,'deg')
        OffRA=(RA(ObjectInd,CondForFit)-nanmean(RA(ObjectInd,CondForFit))).*cos(Dec(ObjectInd,CondForFit)./RAD);
        OffDec=Dec(ObjectInd,CondForFit)-nanmean(Dec(ObjectInd,CondForFit));
    
    else
        OffRA=(RA(ObjectInd,CondForFit)-nanmean(RA(ObjectInd,CondForFit))).*cos(Dec(ObjectInd,CondForFit));
        OffDec=Dec(ObjectInd,CondForFit)-nanmean(Dec(ObjectInd,CondForFit));
    end
    
    % fit for proper motion and position with a given parallax by GAIA
    PMfit(ObjectInd)=Asmtry.fit_pm_parallax(matchdata.JD(ObjectInd,CondForFit)',OffRA',OffDec'...
                                        ,'ErrRA',astormetryrms(CondForFit),'ErrDec',astormetryrms(CondForFit),...
                                        'RA',(nanmean(RA(ObjectInd,CondForFit))),'Dec',nanmean(Dec(ObjectInd,CondForFit)),...
                                        'GivenPlx',GAIAAstCat.Cat(ObjectInd,GAIAAstCat.Col.Plx),'Plx_is_Given',true,...
                                        'RefEpoch', JD2000 + 15.5/JD2yr );
    PMfit(ObjectInd).Par(1) = PMfit(ObjectInd).Par(1) + (nanmean(RA(ObjectInd,CondForFit)));
    PMfit(ObjectInd).Par(3) = PMfit(ObjectInd).Par(3) + (nanmean(Dec(ObjectInd,CondForFit)));
end


ComData.RAfit = RAfit;
ComData.Decfit = Decfit;
ComData.RAclipfit = RAfitclip;
ComData.ParallaxFit= PMfit;


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