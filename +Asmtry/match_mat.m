function [MatchedMat,AstOut,Summary]= match_mat(AstCatalog,varargin)
%{
generate the matched mat for objects with several conditions


%}
RAD=180/pi;
DefV.Units = {'rad'};
DefV.match_SearchRadius = 2;
DefV.ImageSize=[2048 4096];
DefV.ApperaFactor=0.9;
DefV.ImageHighBound=1;
DefV.ImageLowBound=0;
DefV.MaxMagBound=14;
DefV.MinMagBound=8;
DefV.OnlyAstrometryUsed=false;
DefV.Colls2return={'JD','XWIN_IMAGE','YWIN_IMAGE','MAG_PSF','ALPHAWIN_J2000','DELTAWIN_J2000'};
DefV.JD_head = 'OBSJD';
%DefV.Colls2return={'XWIN_IMAGE','YWIN_IMAGE','MAG_PSF','ALPHAWIN_J2000','DELTAWIN_J2000'};
DefV.Survey = 'PTF';
InPar = InArg.populate_keyval(DefV,varargin,mfilename);
if strcmp(InPar.Survey, 'ZTF')
    InPar.ImageSize = [3072 3080];
end

switch lower(InPar.Units{1})
    case 'rad'
        UnitsCells = {'rad'; 'rad'; 'pix'; 'pix'; 'pix'; 'pix'};
    case 'deg'
        UnitsCells = {'deg'; 'deg'; 'pix'; 'pix'; 'pix'; 'pix'};
end

[AstOut,~]=match(AstCatalog,AstCatalog(1), 'SearchRad' ,InPar.match_SearchRadius,'CatUnits',UnitsCells,'RefUnits',InPar.Units{1},'CatUnits',InPar.Units);


for i=1:length(AstOut)
    AstOut(i).Cat = AstOut(i).Cat(:,1:44);
    JD=(cell2mat(AstCatalog(i).getkey(InPar.JD_head)));
    AstOut(i).Cat=[AstOut(i).Cat JD*ones(size(AstOut(i).Cat(:,1)))];
    AstOut(i).Col.JD=length(AstOut(i).Cat(1,:));
    AstOut(i).ColCell=[AstOut(i).ColCell;{'JD'}];
end



Colls2return=InPar.Colls2return;
%chain all the AstOut into a matched matrix format
[Res,Summary,~]=astcat2matched_array(AstOut,Colls2return)  ;
ConditionForAppearence=Summary.Nnn>InPar.ApperaFactor*length(AstOut)...
    & sum(~isnan(Res.ALPHAWIN_J2000)')'>=  InPar.ApperaFactor*length(AstOut);%& sum(~isnan(Res.ALPHAWIN_J2000(:,:)'))' >InPar.ApperaFactor*length(AstOut);
%ConditionForLocationX= nanmean(Res.XWIN_IMAGE,2)>InPar.ImageLowBound*InPar.ImageSize(1) &nanmean(Res.XWIN_IMAGE,2)<InPar.ImageHighBound*InPar.ImageSize(1);
%ConditionForLocationY= nanmean(Res.YWIN_IMAGE,2)>InPar.ImageLowBound*InPar.ImageSize(2) & nanmean(Res.YWIN_IMAGE,2)<InPar.ImageHighBound*InPar.ImageSize(2);
%ConditionForMagnitude= nanmean(Res.MAG_PSF,2)<InPar.MaxMagBound &nanmean(Res.MAG_PSF,2)>InPar.MinMagBound;
CondTot=ConditionForAppearence;


for i=1:length(Colls2return)
    MatchedMat.(Colls2return{i})=Res.(Colls2return{i})(CondTot,:);
end

end