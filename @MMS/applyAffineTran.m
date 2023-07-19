function applyAffineTran(Obj,AffineMat,Args)

arguments
    Obj;
    AffineMat;
    Args.ColNameX = 'X';
    Args.ColNameY = 'Y';
end



for Iepoch=1:Obj.Nepoch
    Xvec  = designMatrixEpoch(Obj,Iepoch,{Args.ColNameX,Args.ColNameY,[]}, {1,1,[]})';
    %Xvec = [CM.MS.Data.(Args.ColNameX)(Iepoch,:);CM.MS.Data.Y(Iepoch,:);ones(size(CM.MS.Data.X(Iepoch,:)))];
    Xtag = AffineMat{Iepoch} * Xvec ;
    Obj.Data.(Args.ColNameX)(Iepoch,:) = Xtag(1,:);
    Obj.Data.(Args.ColNameY)(Iepoch,:) = Xtag(2,:);
end