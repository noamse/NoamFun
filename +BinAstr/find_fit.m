function [bestPar,bestind,a]  = find_fit(Resid,A,ParGrid,varargin)


%{
Find the best parameter of the fit, given the residuals and amplitude
matrices


%}

DefV. D1= 10;           %[km]
DefV. D2= 5 ;           %[km]
DefV. plotFlag= false;
InPar = InArg.populate_keyval(DefV,varargin,mfilename);


[~,bestindvec]=min(Resid(:));
[bestind.Omega,bestind.i,bestind.T,bestind.P] = ind2sub(size(A),bestindvec);
bestPar.Omega=ParGrid.Omega(bestind.Omega);
bestPar.Inc=ParGrid.Inc(bestind.i);
bestPar.T = ParGrid.T(bestind.T);
bestPar.P = ParGrid.P(bestind.P);
bestPar.Res= Resid(bestind.Omega,bestind.i,bestind.T,bestind.P);
bestPar.alpha = A(bestind.Omega,bestind.i,bestind.T,bestind.P);

D1= InPar.D1;
D2= InPar.D2;%


FAC= (-D2^3*D1^2 + D2^2*D1^3)./((D1^3 + D2^3)*(D1^2 +D2^2)); %[unitless]
a = bestPar.alpha*tand(1/3600/1000)./FAC *  (constant.au/1e5); % [km]

if(InPar.plotFlag)
    ResidForPlot_P = reshape(Resid(bestind.Omega,bestind.i,bestind.T,:),[],1);
    ResidForPlot_i_T =reshape(Resid(bestind.Omega,:,:,bestind.P),[],numel(ParGrid.T));    

    plot(ParGrid.f,ResidForPlot_P)
    title('Res as functio of freq')
    xlabel('freq [1/day]')
    ylabel('res [mas]')
    figure;
    surface(ParGrid.T,ParGrid.Inc,ResidForPlot_i_T)
    title('')

end