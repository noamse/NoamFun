function printargs(functionpath)
% Print the arguments section of a function.




F = {};


fid = fopen(functionpath,'r');
isend = false;
arguments_found = false;

while ~feof(fid) && ~isend
    
    st = fgetl(fid);       
    disp(st);
    stsplit = strsplit(st,{' ',';',','});
    
    if  any(strcmp(stsplit,'arguments'))
        arguments_found= true;
        continue;
    end
    
    if  any(strcmp(stsplit,'end'))
        isend= true;
        continue;
    end
    if arguments_found
        
        F = [F;st]; 
       
    end
    
end
for I = 1:numel(F)
    disp(F{I});

end
