function [xmid,ymid,loc,N]= calc_bin_fun(X,Y,varargin)


DefV.edges=[];
DefV.Nbins = 10;
DefV.fun=@mean;
InPar = InArg.populate_keyval(DefV,varargin,mfilename);


if isempty(InPar.edges)
    edges = linspace(min(X),max(X),InPar.Nbins);
else 
    edges = InPar.edges;
end

Nbins = numel(edges);



[N,~,loc]=histcounts(X,edges);
fun_calc=nan(numel(N),1);
for i =1:numel(N)
    flag= loc==i;
    ymid(i)= InPar.fun(Y(flag));
end

xmid = 0.5*(edges(1:end-1)+edges(2:end));
