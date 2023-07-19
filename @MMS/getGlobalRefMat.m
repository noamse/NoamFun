function [X,Y] = getGlobalRefMat(Obj,Args)

arguments
    Obj
    Args.JD = [];
    
end


if isempty(Args.JD)
    JD=Obj.JD;
else
    JD = Args.JD;
end
if isempty(Obj.PMX)||isempty(Obj.PMY)
    error('Proper motion is not populate in MMS obj)')
end
JD0 = Obj.JD0;
Nsrc = Obj.Nsrc;
X = nan(Obj.Nepoch,Nsrc);
Y = nan(Obj.Nepoch,Nsrc);
for Iepoch = 1:Obj.Nepoch
    
    H = ones(Nsrc,1).*[1,(JD(Iepoch)- JD0 )];
    Xt = diag(H*Obj.PMX);
    Yt = diag(H*Obj.PMY);
    X(Iepoch,:) =Xt';
    Y(Iepoch,:) =Yt';
end