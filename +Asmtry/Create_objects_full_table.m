function [DataAstCat,MatchData,RefCat]= Create_objects_full_table(astcat,varargin)
% Generate matrix of all the objects that appear in each image. 
% Coordinates are in rad
% The uncerntities parameters are in marsc 

%call - 
%        [DataAstCat,MatchData,RefCat]= Create_objects_full_table(astcat)

JD0=2450000;
JD2yr=1/365.25;
Rad2Deg=180/pi;
Deg2marcs = 1000*3600;
DefV.SearchRadius= 1;
DefV.ImageSize=[2048 4096];
DefV.ApperaFactor=0.95;
DefV.ImageHighBound=1;
DefV.ImageLowBound=0;
DefV.MaxMagBound=17;
DefV.MinMagBound=13;
DefV.OnlyAstrometryUsed=true;
DefV.Colls2return={'JD','XWIN_IMAGE','YWIN_IMAGE','ALPHAWIN_J2000','DELTAWIN_J2000','MAG_PSF',...
    'ResX','ResY','Res','Mag','rrmsN','RefColor','PA','LST','AssymErr','ImgIndex','FieldNum'};
DefV.FieldNum = 0;
%{'JD','XWIN_IMAGE','YWIN_IMAGE','MAG_PSF','ALPHAWIN_J2000','DELTAWIN_J2000'};
%DefV.GAIAColls2return= {'RA','Dec','ErrRA','ErrDec','Plx','PMRA','ErrRA','PMDec','ErrPMDec','ExcessNoise','MagG','Trf}
InPar = InArg.populate_keyval(DefV,varargin,mfilename);






Nel=numel(astcat);
for i=1:Nel
    %index=sort(astcat(i).UserData.R.IndexInSimN);
    %astcat(i).Cat=astcat(i).Cat(index,:);
    LSTdate=cell2mat(astcat(i).getkey('OBSLST'));
    LST=rem(datenum(LSTdate),1);
    telairmass=cell2mat(astcat(i).getkey('AIRMASS'));
    Lat=cell2mat(astcat(i).getkey('OBSLAT'));
    RA=astcat(i).Cat(:,astcat(i).Col.ALPHAWIN_J2000);
    
    Dec=astcat(i).Cat(:,astcat(i).Col.DELTAWIN_J2000);
    

    PA=celestial.coo.parallactic_angle([RA, Dec], LST, Lat./Rad2Deg) ;
    ResX=       astcat(i).UserData.R.ResidX(astcat(i).UserData.R.FlagG)*Deg2marcs ;
    ResY=       astcat(i).UserData.R.ResidY(astcat(i).UserData.R.FlagG)*Deg2marcs ;
    Res =       astcat(i).UserData.R.Resid(astcat(i).UserData.R.FlagG)*Deg2marcs ;
    Mag =       astcat(i).UserData.R.RefMag(astcat(i).UserData.R.FlagG);
    AssymErr=   ones(size(ResX))*astcat(i).UserData.R.MinAssymErr*Deg2marcs ;
    rrmsN=   ones(size(ResX))*astcat(i).UserData.R.rrmsN*Deg2marcs ;
    RefColor=   astcat(i).UserData.R.RefColor(astcat(i).UserData.R.FlagG);
    LSTcol = ones(size(ResX))*LST;
    ImgIndex= ones(size(ResX)).*i;
    FieldNum= ones(size(ResX)).*InPar.FieldNum;
    
    astcat(i)=col_insert(astcat(i),ResX,numel(astcat(i).Cat(1,:)),'ResX');
    astcat(i)=col_insert(astcat(i),ResY,numel(astcat(i).Cat(1,:)),'ResY');
    astcat(i)=col_insert(astcat(i),Res,numel(astcat(i).Cat(1,:)),'Res');
    astcat(i)=col_insert(astcat(i),Mag,numel(astcat(i).Cat(1,:)),'Mag');
    astcat(i)=col_insert(astcat(i),AssymErr,numel(astcat(i).Cat(1,:)),'AssymErr');
    astcat(i)=col_insert(astcat(i),rrmsN,numel(astcat(i).Cat(1,:)),'rrmsN');
    astcat(i)=col_insert(astcat(i),RefColor,numel(astcat(i).Cat(1,:)),'RefColor');
    astcat(i)=col_insert(astcat(i),PA,numel(astcat(i).Cat(1,:)),'PA');
    astcat(i)=col_insert(astcat(i),LSTcol,numel(astcat(i).Cat(1,:)),'LST');
    astcat(i)=col_insert(astcat(i),ImgIndex,numel(astcat(i).Cat(1,:)),'ImgIndex');
    astcat(i)=col_insert(astcat(i),FieldNum,numel(astcat(i).Cat(1,:)),'FieldNum');
end




[MatchData,AstOut]= Asmtry.match_mat(astcat,'Colls2return',InPar.Colls2return,'ApperaFactor',InPar.ApperaFactor,'match_SearchRadius',InPar.SearchRadius...
    ,'MaxMagBound',InPar.MaxMagBound,'MinMagBound',InPar.MinMagBound);
RefCat =  Asmtry.compare_cat(MatchData);

SampleSize = size(MatchData.JD);

Cells =[InPar.Colls2return RefCat.ColCell {'ObjIndex'}];
DataMat = nan(numel(MatchData.JD),numel(Cells));
maxIndCellFromPTF = numel(InPar.Colls2return);
SampleInd = 1;
for ObjInd=1:SampleSize(1)
    for ImageInd = 1:SampleSize(2)
        for IndField=1:maxIndCellFromPTF
            DataMat(SampleInd,IndField) = MatchData.(Cells{IndField})(ObjInd,ImageInd);
        end
        %DataMat(SampleInd,maxIndCellFromPTF+1:end) = RefCat.Cat(ObjInd,:);
        DataMat(SampleInd,:) = [DataMat(SampleInd,1:maxIndCellFromPTF) RefCat.Cat(ObjInd,:) ObjInd];
        SampleInd = SampleInd +1;
    end
end


Col = Asmtry.generate_col_struct(Cells);

DataAstCat = AstCat;
DataAstCat.ColCell = Cells;
DataAstCat.Cat = DataMat;
DataAstCat.Col = Col;

end