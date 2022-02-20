function Head = read_header(filenameorg,varargin)

DefV.CCDSEC               = [];  % section to read


InPar = InArg.populate_keyval(DefV,varargin,mfilename);
fid = fopen(filenameorg,'r');
filename = fopen(fid);
fclose(fid);
Head = HEAD;
if any(isspace(filename))
    tmpnm= tempname;
    copyfile(filename,tmpnm);
    
    H=FITS.read_header(tmpnm);
    %S.ImageFileName =filenameorg;
    delete(tmpnm);
else
    H=FITS.read2sim(filename);
end
Head.Header = H;