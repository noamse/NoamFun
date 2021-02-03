function [yr,xr]= interp_sinc(y,x,xr)
% time domain sinc interpolation
% x- frequency domain

%xr= linspace(0,length(y),length(y)*m);
T1=mean(diff(x));
yr=[];
for i=1:numel(xr)
    yr(i)= sum(y.*sinc(((x-xr(i))./T1)));
end
%xr = min(x)+T1*xr;
%yr=yr(m:end-1);
%xr=xr(end);
end