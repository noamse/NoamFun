function applySourceFlag(Obj,Flag)

if Obj.Nsrc ~= numel(Flag)
    return
end

Obj.Data = flagStructField(Obj.Data,Flag,'FlagByCol',true);
try
    Obj.PMX = Obj.PMX(:,Flag);
    Obj.PMY = Obj.PMY(:,Flag);
    Obj.PMErr= Obj.PMErr(:,Flag);
catch
    disp('No proper motion to flag');
end
try
    Obj.PMPlx= Obj.PMPlx(:,Flag);
    Obj.PMPlxErr= Obj.PMPlxErr(:,Flag);
catch
    disp('No Parallax parameters to flag');
end
end