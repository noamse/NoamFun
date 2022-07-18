function [xmid,mean_bin,std_bin,loc,N]= calc_bin_mean_std(X,Y,varargin)


DefV.edges=[];
DefV.Nbins = 10;
%DefV.fun=@mean;
DefV.MinNinBin = 5;
InPar = InArg.populate_keyval(DefV,varargin,mfilename);


if isempty(InPar.edges)
    edges = linspace(min(X),max(X),InPar.Nbins)';
else
    
    edges = InPar.edges;
end





[N,~,loc]=histcounts(X,edges);
mean_bin = nan(numel(N),1);
std_bin = nan(numel(N),1);
for i =1:numel(N)
    flag= loc==i;
    if sum(flag)<InPar.MinNinBin
        mean_bin(i)=nan;
        std_bin(i)=nan;
        continue;
    end
    Yt= Y(flag);
    mean_t = tools.math.stat.rmean(Yt,1);
    std_t  = tools.math.stat.rstd(Yt);
    
    isout= isoutlier(Yt,'median');
    mean_bin(i)= tools.math.stat.rmean(Yt(~isout),1);
    std_bin(i)= tools.math.stat.rstd(Y(~isout));
    
end

xmid = 0.5*(edges(1:end-1)+edges(2:end));
