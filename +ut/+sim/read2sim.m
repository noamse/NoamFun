function Sim=read2sim(Image,varargin)
    
    DefV.HDUnum               = 1;
    DefV.CCDSEC               = [];  % section to read
    DefV.Sim                  = [];  % read into existing SIM
    DefV.ExecField            = SIM.ImageField;   % read into field
    DefV.ReadHead             = true;
    DefV.HDUnum               = 1;
    DefV.PopWCS               = true;
    InPar = InArg.populate_keyval(DefV,varargin,mfilename);
    
    
