function [PMX,PMY,PMErr] = fitProperMotion(Obj,Args)

arguments
    Obj;
    Args.ClipMethod = 'movemedian'
    Args.MoveWindowSize = 100;
    Args.JD0=[];
    Args.SecondIterationClipPrctile = [10,90];
end


if isempty(Args.JD0)
    JD0=Obj.JD0;
else
    JD0=Args.JD0;
end

PMX = nan(2,Obj.Nsrc);
PMY = nan(2,Obj.Nsrc);
PMErr = nan(2,Obj.Nsrc);


H = Obj.designMatrixPM;

for Isrc = 1:Obj.Nsrc
    
    
    XY = Obj.getTimeSeriesField(Isrc,{'X','Y'});
    
    
    Flag = ~isnan(XY(:,1)) & ~isnan(XY(:,2)) ;%& w>=0 ;

    Xt = XY(Flag,1);
    Yt = XY(Flag,2);
    %wt = w(Flag);
    Ht = H(Flag,:);
    Outx = isoutlier(Xt,'movmean',Args.MoveWindowSize);
    Outy = isoutlier(Yt,'movmean',Args.MoveWindowSize);
    
    Out = Outx | Outy;
    Xt = Xt(~Out);
    Yt = Yt(~Out);
    %wt = wt(~Out);
    Ht = Ht(~Out,:);
    %fwhm = CM.MS.Data.fwhm(Flag,Iobj);
    ParXTemp= lscov(Ht,Xt);
    ParYTemp= lscov(Ht,Yt);
    
    [~ ,rm_clip_x] = rmoutliers(Ht*ParXTemp - Xt,'percentiles',Args.SecondIterationClipPrctile);
    [~ ,rm_clip_y] = rmoutliers(Ht*ParYTemp - Yt,'percentiles',Args.SecondIterationClipPrctile);
    clip = rm_clip_y | rm_clip_x;
    
    [PMX(:,Isrc),PMXErrTemp] = lscov(Ht(~clip,:),Xt(~clip));
    [PMY(:,Isrc),PMYErrTemp] = lscov(Ht(~clip,:),Yt(~clip));
    PMErr(:,Isrc) = [PMXErrTemp(1);PMYErrTemp(1)];
    
end




