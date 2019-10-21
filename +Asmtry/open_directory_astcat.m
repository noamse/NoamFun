function [AstCatalog] = open_directory_astcat(varargin)
%{
Chain a files from directory into struct array.
%}
DefV.Directory='/data/noamse/Astrometry/Data/Catalogs/catPTF_27_11_18/'; 
DefV.Finish='.mat';
DefV.NameOfFieldInSavedFile='AstCatTemp';
DefV.NewUnitsAstCat=[];
DefV.ColsUnits= {'ALPHAWIN_J2000','DELTAWIN_J2000'};
DefV.Index=[];

InPar = InArg.populate_keyval(DefV,varargin,mfilename);

FileNames = Asmtry.read_dir_names ( InPar.Directory,'type','.mat','sortFlag',true,...
                    'TextBefSort','AstCat_');

                
if (~isempty(InPar.Index))
   FileNames= FileNames(InPar.Index); 
end




AstCatalog=AstCat(length(FileNames));
for i=1:length(FileNames)
   Temp=load([InPar.Directory cell2mat(FileNames(i))]);
   AstCatalog(i)=Temp.(InPar.NameOfFieldInSavedFile);
   if (~isempty(InPar.NewUnitsAstCat))
        
        AstCatalog(i).ColUnits{AstCatalog(i).Col.(InPar.ColsUnits{1})} = InPar.NewUnitsAstCat;
        AstCatalog(i).ColUnits{AstCatalog(i).Col.(InPar.ColsUnits{2})} = InPar.NewUnitsAstCat;
        
   end
end


end

