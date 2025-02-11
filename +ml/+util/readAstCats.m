function astcats  = read_astcats(DirPath,Args)




arguments
    DirPath;
    Args.NamePattern = [];
    Args.FileType = 'mat';
    Args.CatFieldName = 'AstCat';
    
end



dir_obj= dir([DirPath,'*',Args.NamePattern,'*.', Args.FileType]);
JD=[];
astcats = AstroCatalog([1,numel(dir_obj)]);
for i = 1:numel(dir_obj)
    AT = load(ut.fullpath(dir_obj,i,'IsFile',true));
    
    astcats(i)=AT.(Args.CatFieldName) ;
    JD(i) = AT.(Args.CatFieldName).JD;
end


[~,Isort] = sort(JD);
astcats=astcats(Isort);
