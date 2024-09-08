function [ParS] = initiateParS(AS,Args)

arguments
    AS;
    Args.Plx = true;
    Args.PlxIn = [];
    Args.PMin = [];
end

if AS.Plx
    ParS = zeros(5,AS.NsrcIn);
    if ~isempty(Args.PlxIn)
        Plxin = Args.Plxin;
    else
        Plxin = exprnd(AS.MuPlx,1,AS.NsrcIn);
    end
else
    ParS = zeros(4,AS.NsrcIn);
end

if isempty(Args.PMin)
    MuPm = repmat(reshape(AS.MuPM,2,1),1,AS.NsrcIn);
    SigmaPM = repmat(reshape(AS.MuPM,2,1),1,AS.NsrcIn);
    PMin = normrnd(MuPm,SigmaPM,2,AS.NsrcIn);
else
    PMin = Args.PMin;
end
Xin = rand(AS.NsrcIn,1).*AS.Npix;%AS.medianFieldSource({'X'});
Yin = rand(AS.NsrcIn,1).*AS.Npix;%AS.medianFieldSource({'Y'});


ParS([1,2],:)= reshape([Xin,Yin],2,AS.NsrcIn);
ParS([3,4],:) = PMin;
ParS(5,:) = reshape(Plxin,1,AS.NsrcIn);
end