function save_file(path,var,varargin)
DefV.nocompress=false;
InPar = InArg.populate_keyval(DefV,varargin,mfilename);

if InPar.nocompress
    save(path,'var','-v7.3')
else
    save(path,'var')
end