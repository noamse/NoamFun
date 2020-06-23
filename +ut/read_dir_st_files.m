function st= read_dir_st_files(dirpath,varargin)
DefV.FileType = '.mat';

InPar = InArg.populate_keyval(DefV,varargin,mfilename);

astdir= dir([dirpath '*' InPar.FileType]);
for i =1:numel(astdir)
    a= load([astdir(i).folder '/' astdir(i).name]);
    fname=fieldnames(a);
    st(i)= a.(fname{1});
end