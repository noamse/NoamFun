function H = designMatrixPM(Obj,Args)

arguments
    Obj;
    Args.JD0=[];
    
    
end

if isempty(Args.JD0)
    JD0=Obj.JD0;
else
    JD0=Args.JD0;
end

if size(Obj.JD,2)==1
    H= [ones(Obj.Nepoch,1),Obj.JD - JD0];
else
    H= [ones(Obj.Nepoch,1),resghape(Obj.JD,Obj.Nepoch,1) - JD0];
end




end