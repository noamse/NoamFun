function ogle_cat= readOgleCatalog(SavePath,Args)

arguments
    SavePath;
    Args.SavedCatFileName = 'ogle_cat.mat';
    Args.CatFieldName = 'ogle_cat';
    
end
a= load([SavePath Args.SavedCatFileName]);
ogle_cat=a.(Args.CatFieldName);