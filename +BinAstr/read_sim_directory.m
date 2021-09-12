function [Resid,DataOut]  = read_sim_directory(dirpath,varargin)
InPar =inputParser;
addOptional(InPar ,'ResidName','Resid_sim');
parse(InPar,varargin{:});


Resid=[];
A=[];
dirarray = dir([dirpath '*.mat']);
for i =1:numel(dirarray)
   
    DataT = load(ut.fullpath(dirarray,i,'IsFile',true));
    %TempResid = DataT.(InPar.Results.ResidName)(:,1);
    %Resid(:,i) = TempResid;%DataT.(InPar.Results.ResidName);
    Resid(:,i) =DataT.(InPar.Results.ResidName)(:,1);
    [~,imax]= min(Resid(:,i));
    try 
        A(i,:) = DataT.A(imax,:);
    catch
        ddd=1;
    end


    try 
        exitflag(i)= DataT.exitflag;
    catch
        ddd=1;
    end

end
DataOut.A=A;
DataOut.JPL = DataT.JPL;
DataOut.ParGrid =   DataT.ParGrid;
DataOut.ParGridCol= DataT.ParGridCol;
DataOut.NumFilesDir = numel(dirarray);

try
    DataOut.sigma_astrometry = DataT.sigma_astrometry(DataT.IndNoise);
catch
    try 
        DataOut.sigma_astrometry = DataT.sigma_astrometry;
    catch 
        ddd=1;
    end
end


try 
    DataOut.exitflag = exitflag;
catch
    ddd=1;
end
try 
    DataOut.ResTest=DataT.ResTest;
    DataOut.ParGridGod = DataT.ParGridGod;
catch
    ddd=1;
end