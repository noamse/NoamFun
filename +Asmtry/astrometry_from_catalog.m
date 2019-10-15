function [] = astrometry_from_catalog(varargin)

% run astrometry direct from saved catalog

DefV.UseCase_TranC      = {'affine_tt_cheby2_4', 100; 'affine_tt_cheby2_3', 70; 'affine_tt',          10; 'affine',             5};
DefV.SaveDirectory='/home/noamse/astro/astrometry/data/Catalogs/Catalog_cheb1/Cat_100019/';
DefV.SaveNameAstCat='AstCat_1.mat';
DefV.StartIndex=1;
DefV.SourceDirectory='/home/noamse/astro/astrometry/data/Catalogs/Im_100019/';
DefV.MaxPMerr=[];
DefV.ApplyParallax= true;
DefV.MaxExcessNoise=1;
DefV.Index=  [];
DefV.Survey= 'PTF';

InPar = InArg.populate_keyval(DefV,varargin,mfilename);


A= dir([InPar.SourceDirectory '*.mat']); 

FileNames=cell(length(A),1);
if isempty(InPar.Index)
   Index = 1:numel(FileNames );
else
    Index = InPar.Index;
end
FileNames={A(Index).name};  

for i=1:numel(FileNames)
    FileNames{i}=strcat(InPar.SourceDirectory,FileNames{i});
end



for i=1:numel(Index)
    i
    load(FileNames{i});
    S = astcat2sim(AstCatTemp);
    ImSize = [cell2mat(S.getkey('NAXIS1')) cell2mat(S.getkey('NAXIS2'))];
    switch InPar.Survey
        case 'PTF'
            [R,Sa] = astrometry(S,'UseCase_TranC',InPar.UseCase_TranC,'MaxPMerr',InPar.MaxPMerr,'MaxExcessNoise',InPar.MaxExcessNoise,'ApplyParallax',true,'ApplyPM',true,'ImSize',ImSize); 
        case 'ZTF'
            [R,Sa] = astrometry(S,'UseCase_TranC',InPar.UseCase_TranC,'MaxPMerr',InPar.MaxPMerr,'MaxExcessNoise',InPar.MaxExcessNoise,'ApplyParallax',true,'SCALE',1.012,'Flip',[1 1],'ApplyPM',true); 
    end
    
    
    %updating the coordinates in the catalog
    Sa=update_coordinates(Sa);
    %creating a AstCat object to save more efficiently
    AstCatTemp=AstCat.sim2astcat(Sa);
    AstCatTemp.UserData.R=R;
    AstCatTemp.UserData.FileName=FileNames{i};
    
    save([InPar.SaveDirectory InPar.SaveNameAstCat],'AstCatTemp');
    InPar.SaveNameAstCat=['AstCat_' num2str(Index(i)) '.mat'];

end