function H = designMatrixPM(Obj,Args)

arguments
    Obj;
    Args.JD = [];
    Args.JD0=[];
    
    
end

if isempty(Args.JD0)
    JD0=Obj.JD0;
else
    JD0=Args.JD0;
end

if ~isempty(Args.JD)
    JD=Args.JD;
else
    JD = Obj.JD;
end

if size(JD ,2)==1
    H= [ones(numel(JD),1),JD  - JD0];
else
    H= [ones(numel(JD),1),resghape(JD ,numel(JD),1) - JD0];
end




end