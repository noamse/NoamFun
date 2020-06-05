function astcat = read_astcat_dir(dirpath,varargin)
DefV.FileType = '.mat';

InPar = InArg.populate_keyval(DefV,varargin,mfilename);

astdir= dir([dirpath '*' InPar.FileType]);
astcat=AstCat(numel(astdir));
for i =1:numel(astdir)
    a= load([astdir(i).folder '/' astdir(i).name]);
    fname=fieldnames(a);
    astcat(i)= a.(fname{1});
end