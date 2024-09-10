function applyParETran(SA,Args)


arguments
    SA;
    Args.A=1;
end



%Aex = SA.AeX;
%Aey = SA.AeY;
for Iepoch = 1:numel(SA.JD)
    Xt = SA.Data.X(Iepoch,:)';
    Yt = SA.Data.Y(Iepoch,:)';
    ZEROS = zeros(size(Xt));
    ONES= ones(size(Xt));
    Aex = [Xt,Yt,ONES,ZEROS,ZEROS,ZEROS];
    Aey = [ZEROS,ZEROS,ZEROS,Xt,Yt,ONES];
    SA.Data.X(Iepoch,:)= (Aex*SA.ParE(:,Iepoch))';
    SA.Data.Y(Iepoch,:) = (Aey*SA.ParE(:,Iepoch))';


end