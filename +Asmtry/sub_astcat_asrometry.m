function [AstCatAstrometry]=  sub_astcat_asrometry(AstCatalog,varargin)

RAD = 180/pi;
DefV.ImSize= [2048 4096];
DefV.SubImSize= [1024,1024];
DefV.Nsub= [2,4];
DefV.SaveDirectory = [];
DefV.SaveNameAstCat= [];
DefV.GaiaRefcolRA= 'GaiaRefRA';
DefV.GaiaRefcolDec = 'GaiaRefDec';
InPar = InArg.populate_keyval(DefV,varargin,mfilename);


AstCatAstrometry= AstCatalog;
for i=1:numel(AstCatalog)
    
    i
    
    [SubAstCat ,~,~]=  Asmtry.AstCat_trim(AstCatalog(i),'SubImgSize',InPar.ImSize,'Nsub',InPar.Nsub);
    rrmsN=[];
    AssymErr=[];
    for j= 1:numel(SubAstCat)
        
        H= celestial.coo.cosined([SubAstCat(j).Cat(:,SubAstCat(j).Col.ALPHAWIN_J2000)/RAD,SubAstCat(j).Cat(:,SubAstCat(j).Col.DELTAWIN_J2000)/RAD]);

        xpar=lscov([SubAstCat(j).Cat(:,SubAstCat(j).Col.XWIN_IMAGE),SubAstCat(j).Cat(:,SubAstCat(j).Col.YWIN_IMAGE)],H);
        Cartfit= (InPar.ImSize/2)*xpar;

        CenterCoo= celestial.coo.cosined(Cartfit);
        if(CenterCoo(1)<0); CenterCoo(1)= 2*pi-abs(CenterCoo(1));end

        [~,I]=sort(SubAstCat(j).Cat(:,SubAstCat(j).Col.YWIN_IMAGE));
        SubAstCat(j).Cat=SubAstCat(j).Cat(I,:);
        [R,Sa] = astrometry(SubAstCat(j),'ImSize',InPar.SubImSize,'RA',CenterCoo(1),'Dec',CenterCoo(2),'CatColMag','MAG_BEST');
        
        % Transform GAIA reference star from X,Y to alpha, delta
        GAIAX = R.RefX(R.FlagG);
        GAIAY = R.RefY(R.FlagG);

        [GAIAalpha,GAIAdelta] = celestial.proj.pr_ignomonic(GAIAX/RAD,GAIAY/RAD,[CenterCoo(1),CenterCoo(2)]);
        %R.IndexInSimN
        Sa=Asmtry.update_coordinates(Sa);
        GaiaRefRA = nan(size(Sa.Cat(:,1)));
        GaiaRefDec = nan(size(Sa.Cat(:,1)));
        GaiaColor = nan(size(Sa.Cat(:,1)));
        GaiaRefRA(R.IndexInSimN) = GAIAalpha;
        GaiaRefDec(R.IndexInSimN) = GAIAdelta;
        GaiaColor(R.IndexInSimN) =  R.RefColor(R.FlagG);
        Sa=col_insert(Sa,GaiaRefRA,numel(Sa.Cat(1,:)),'GaiaRefRA');
        Sa=col_insert(Sa,GaiaRefDec,numel(Sa.Cat(1,:)),'GaiaRefDec');
        SubAstCat(j)= Sa;
        rrmsN(j) = R.rrmsN;
        AssymErr(j) = R.AssymErr;
    end
    astcat =  Asmtry.AstCat_merge(SubAstCat);
    astcat.UserData.R.rrmsN = mean(rrmsN);
    astcat.UserData.R.AssymErr = mean(AssymErr);
    
    if (~isempty(InPar.SaveDirectory))
        InPar.SaveNameAstCat=['AstCat_' num2str(i) '.mat'];
        save([InPar.SaveDirectory InPar.SaveNameAstCat],'astcat');
    end
    AstCatAstrometry(i)=astcat;
end
