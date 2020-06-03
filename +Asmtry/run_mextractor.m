function [] = run_mextractor(Directory,varargin)
%call for mextractor 
%Save AstCat files with some options.
DefV.UseCase_TranC      = {'affine_tt_cheby2_4', 100; 'affine_tt_cheby2_3', 70; 'affine_tt',          10; 'affine',             5};
DefV.SaveDirectory=nan;
DefV.SaveNameAstCat='AstCat_1.mat';
DefV.StartIndex=1;
DefV.SourceDirectory='/data1/noamse/Astrometry/Data/Images/Im_100019/';
DefV.MaxPMerr=[];
DefV.ApplyParallax= true;
DefV.MaxExcessNoise=1;
DefV.Index=  [];
DefV.Survey= 'PTF';
InPar = InArg.populate_keyval(DefV,varargin,mfilename);

A= dir([Directory '*.fits']); 

FileNames=cell(length(A),1);
if isempty(InPar.Index)
   Index = 1:numel(FileNames );
else
    Index = InPar.Index;
end
FileNames={A(Index).name};  

for i=1:numel(FileNames)
    FileNames{i}=strcat(Directory,FileNames{i});
end

for i=1:numel(Index)
    i
    FileNames{i}
    S = FITS.read2sim(FileNames{i}); 
    S = mextractor(S); 
    %updating the coordinates in the catalog
    
    S=update_coordinates(S);
    %creating a AstCat object to save more efficiently
    AstCatTemp=AstCat.sim2astcat(S);
    AstCatTemp.UserData.FileName=FileNames{i};
    InPar.SaveNameAstCat=['AstCat_' num2str(Index(i)) '.mat'];
    save([InPar.SaveDirectory InPar.SaveNameAstCat],'AstCatTemp');
    
    
end
end

