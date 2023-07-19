function RefCat  = loadRefCat(self,Args)

arguments
    self;
    Args.SavedCatFileName = 'RefCat.mat';
    Args.SavedCatFileField = 'RefCat';
    Args.SettingFileName='master.txt';
    Args.SaveCat= true;
    Args.RefCat = [];
    
end

if isempty(Args.RefCat)
    a =load([self.RefCatalogFilePath,Args.SavedCatFileName]);
    RefCat = a.(Args.SavedCatFileField);
else
    RefCat= Args.OgleCat;
end




end