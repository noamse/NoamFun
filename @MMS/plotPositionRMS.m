function [RStdPrcX,RStdPrcY] = plotPositionRMS(Obj,Args)
arguments
   Obj;
   Args.CloseALL=true;
   Args.ClipPrctile = [10,90];
   Args.PlotVsMag = true;
   Args.ColNameMag = 'MAG_PSF';
end
[XPMRef,YPMRef]= getGlobalRefMat(Obj);
X = Obj.getMatrix('X');
Y = Obj.getMatrix('Y');

Flag = false(size(X));
for Isrc = 1:numel(Obj.Nsrc)
    IsOutX = isoutlier(X(:,Isrc)-XPMRef(:,Isrc),'percentile',Args.ClipPrctile);
    IsOutY = isoutlier(Y(:,Isrc)-YPMRef(:,Isrc),'percentile',Args.ClipPrctile);
    Flag(:,Isrc) = ~(IsOutX | IsOutY);
end
X(Flag)=nan;
Y(Flag)=nan;
XPMRef(Flag)=nan;
YPMRef(Flag)=nan;
RStdPrcX= tools.math.stat.rstd(X-XPMRef)'*0.4*1000;
RStdPrcY= tools.math.stat.rstd(Y-YPMRef)'*0.4*1000;
    
    
if Args.PlotVsMag
    if Args.CloseALL
        close all;
    end
    MAG = Obj.medianFieldSource({Args.ColNameMag});
    
    figure;
    semilogy(MAG,RStdPrcX,'.')
    xlabel('MAG PSF');
    ylabel('$\Delta$ X rstd [mas]','Interpreter','latex')
    
    figure;
    semilogy(MAG,RStdPrcY,'.')
    xlabel('MAG PSF');
    ylabel('$\Delta$ Y rstd [mas]','Interpreter','latex')
    
    
    
end