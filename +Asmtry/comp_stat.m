function C = comp_stat(GAIAcat, compcat,varargin)

DefV.pm_axis_alpha = [];
DefV.pm_axis_delta = [];
DefV.BinWidth = 1;
InPar = InArg.populate_keyval(DefV,varargin,mfilename);



Rad2miliArcsec= 3600*1000*180/pi;

%{

RA0 = [];
Dec0 =[] ; 
muRA_used = []; 
muDec_used= [];
for i =1:numel(compcat.RAfit)
    RA0(i)  =  compcat.RAfit(i).fit.p2;
    Dec0(i)    =  compcat.Decfit(i).fit.p2;
    muRA_used(i) = compcat.RAfit(i).fit.p1*cos(Dec0(i));
    muDec_used(i) = compcat.Decfit(i).fit.p1;
end

RA0 = [];
Dec0 =[] ; 
muRA_used = []; 
muDec_used= [];

for i =1:numel(compcat.RAfit)
    RA0(i)  =  compcat.RAclipfit(i,1);
    Dec0(i)    =  compcat.Decclipfit(i,1);
    muRA_used(i) = compcat.RAclipfit(i,2)*cos(Dec0(i));
    muDec_used(i) = compcat.Decclipfit(i,2);
end


RA0 = [];
Dec0 =[] ; 
muRA_used = []; 
muDec_used= [];

for i =1:numel(compcat.RAfit)
    RA0(i)  =  compcat.ParallaxFit(i).Par(1);
    Dec0(i)    =  compcat.ParallaxFit(i).Par(3);
    muRA_used(i) = compcat.ParallaxFit(i).Par(2);
    muDec_used(i) = compcat.ParallaxFit(i).Par(4);
end
%}


RA0  =  compcat.asmtry_fit_clip(:,1);
Dec0    =  compcat.asmtry_fit_clip(:,3);
muRA_used = compcat.asmtry_fit_clip(:,2).*cos(Dec0);
muDec_used = compcat.asmtry_fit_clip(:,4);

figure; 
plot(Rad2miliArcsec*muRA_used, GAIAcat.Cat(:,GAIAcat.Col.PMRA),'k.');
title('\mu_{\alpha} vs GAIA')
xlabel('\mu_{\alpha} [mas]')
ylabel('\mu_{\alpha}^{Gaia} [mas]')
axis(InPar.pm_axis_alpha);

figure;
plot(Rad2miliArcsec*muDec_used, GAIAcat.Cat(:,GAIAcat.Col.PMDec),'k.');
title('\mu_{\delta} vs GAIA')
xlabel('\mu_{\delta} [mas]')
ylabel('\mu_{\delta}^{Gaia} [mas]')
axis(InPar.pm_axis_delta);


figure;
histogram( Rad2miliArcsec.*(RA0-GAIAcat.Cat(:,GAIAcat.Col.RA)).*cos(GAIAcat.Cat(:,GAIAcat.Col.Dec)),'BinWidth',InPar.BinWidth);

xlabel('(\alpha - \alpha_{GAIA})cos(\delta) [mas]')



figure;
histogram( Rad2miliArcsec.*(Dec0-GAIAcat.Cat(:,GAIAcat.Col.Dec)),'BinWidth',InPar.BinWidth);

xlabel('\delta - \delta_{GAIA} [mas]')


figure; 
histogram( Rad2miliArcsec*muDec_used-GAIAcat.Cat(:,GAIAcat.Col.PMDec),'BinWidth',InPar.BinWidth*0.5);%'FaceColor','#7E2F8E');
xlabel('\mu_{\delta} - \mu_{\delta}^{GAIA} [mas]')

C.RA_std_used = std((RA0- GAIAcat.Cat(:,1)).*cos(GAIAcat.Cat(:,2)))* Rad2miliArcsec;
C.Dec_std_used =std(Dec0- GAIAcat.Cat(:,2))* Rad2miliArcsec;




C.RA_rstd_used = Util.stat.rstd((RA0- GAIAcat.Cat(:,1)).*cos(GAIAcat.Cat(:,2)))* Rad2miliArcsec;
C.Dec_rstd_used =Util.stat.rstd(Dec0- GAIAcat.Cat(:,2))* Rad2miliArcsec;


C.mu_RA_rstd_used = Util.stat.rstd(Rad2miliArcsec*muRA_used- GAIAcat.Cat(:,GAIAcat.Col.PMRA));
C.mu_Dec_rstd_used = Util.stat.rstd(Rad2miliArcsec*muDec_used- GAIAcat.Cat(:,GAIAcat.Col.PMDec));
C.alpha_gaia_res =  RA0- GAIAcat.Cat(:,1);
C.delta_gaia_res = Dec0- GAIAcat.Cat(:,2);
end