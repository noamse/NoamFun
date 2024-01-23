function [Mag,MagErr,Out] = plotMagErr(Obj,Args)

arguments 
   Obj;
   Args.CloseAll = true;
   Args.NewFigure = true;
   Args.SigmaClip = [];
   Args.PrctileClip = [10,90];
    
    
end

if Args.CloseAll
    close all;
end
if Args.NewFigure
    figure;
end

Mag= Obj.medianFieldSource({'MAG_PSF'});
RefMag= Obj.medianFieldSource({'RefMag'});

%[Mag,Isort] = sort(Mag);
%RefMag = RefMag(Isort);
H = [ones(size(RefMag)),RefMag];
Par  = H\Mag;
MagErr = Mag-H*Par;
ErrPar = H\MagErr;
plot(RefMag,Mag,'.');
xlabel('RefMag','interpreter','latex')
ylabel('Mag','interpreter','latex')
hold on;
%semilogy(RefMag,abs(H*ErrPar));
if ~isempty(Args.SigmaClip)
    Delta = abs(MagErr-H*ErrPar);
    StdDelta = nanstd(Delta);
    Out =  Delta> Args.SigmaClip*StdDelta;
else
    
    Out=isoutlier(MagErr-H*ErrPar,'percentiles',Args.PrctileClip );
end


plot(RefMag(Out),(Mag(Out)),'*');
