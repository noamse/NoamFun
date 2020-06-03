function S = read2sim(filenameorg)

fid = fopen(filenameorg,'r');
filename = fopen(fid);
fclose(fid);

if any(isspace(filename))
    tmpnm= tempname;
    copyfile(filename,tmpnm);
    
    S=FITS.read2sim(tmpnm);
    S.ImageFileName =filenameorg;
    delete(tmpnm);
else
    S=FITS.read2sim(filename);
end
