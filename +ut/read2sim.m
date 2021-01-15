function S = read2sim(filenameorg,varargin)
DefV.CCDSEC               = [];  % section to read


InPar = InArg.populate_keyval(DefV,varargin,mfilename);
fid = fopen(filenameorg,'r');
filename = fopen(fid);
fclose(fid);

if any(isspace(filename))
    tmpnm= tempname;
    copyfile(filename,tmpnm);
    
    S=FITS.read2sim(tmpnm,'CCDSEC',InPar.CCDSEC);
    S.ImageFileName =filenameorg;
    delete(tmpnm);
else
    S=FITS.read2sim(filename,'CCDSEC',InPar.CCDSEC);
end
