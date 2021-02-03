function [Resid,DataOut]  = read_sim_directory(dirpath,varargin)
InPar =inputParser;
addOptional(InPar ,'ResidName','Resid_sim');
parse(InPar,varargin{:});


Resid=[];
dirarray = dir([dirpath '*.mat']);
for i =1:numel(dirarray)
   
    DataT = load(ut.fullpath(dirarray,i,'IsFile',true));
    Resid(:,i) = DataT.(InPar.Results.ResidName);
    
end
DataOut.JPL = DataT.JPL;
DataOut.ParGrid =   DataT.ParGrid;
DataOut.ParGridCol= DataT.ParGridCol;
DataOut.ParGridGod = DataT.ParGridGod;
DataOut.NumFilesDir = numel(dirarray);
try
    DataOut.sigma_astrometry = DataT.sigma_astrometry(DataT.IndNoise);
end