function [HeadCell,Nhdu]=read_header(Image,HDUnum)


if nargin<2
    HDUnum = 1;
end

fid = fopen(Image,'r');
filename = fopen(fid);
fclose(fid);

if any(isspace(filename))
    tmpnm= tempname;
    copyfile(filename,tmpnm);
    
    [HeadCell,Nhdu]=FITS.read_header(tmpnm,HDUnum);
    delete(tmpnm);
else
    [HeadCell,Nhdu]=FITS.read_header(filename,HDUnum);
end

