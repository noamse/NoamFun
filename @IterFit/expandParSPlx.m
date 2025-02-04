function ParS = expandParSPlx(IF,Args) 
arguments
    IF;
    Args.Plx= true; 
end

if numel(IF.ParS(:,1))==4

    ParS = [IF.ParS;zeros(1,IF.Nsrc)];
else

    ParS =IF.ParS;
end


