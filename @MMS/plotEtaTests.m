function plotEtaTests(Obj,Args)

arguments
    Obj;
    Args.Nbin= 20;
    Args.CloseAll = true;
    Args.Coo = [];
    Args.NewFigure = true;
    Args.BinSize=20;  %[days]
    Args.CipPrctile = [10,90];
end

if Args.CloseAll
    close all;
end

H = Obj.designMatrixPM;
X = Obj.getMatrix('X');
Y = Obj.getMatrix('Y');
Mag = Obj.getMatrix('MAG_PSF');
PMX = Obj.PMX;
PMY = Obj.PMY;

IsOutX= isoutlier(X-H*PMX,'percentile',Args.CipPrctile);
IsOutY= isoutlier(Y-H*PMY,'percentile',Args.CipPrctile);
Flag= ~(IsOutX|IsOutY);
X(Flag) = nan;
Y(Flag) = nan;
Mag(Flag) = nan;

StdPrcX= nanstd(X-H*PMX)*0.4*1000;
StdPrcY= nanstd(Y-H*PMY)*0.4*1000;


for ISrc = 1:Obj.Nsrc
    
    %B = timeSeries.bin.binningFast([nanmean(mag)', stdprc'], Args.BinSize,[NaN NaN],{'MidBin', Args.fun_prctl, @tools.math.stat.rstd});
    Bx = timeSeries.bin.binningFast([Obj.JD, X(:,ISrc)], Args.BinSize,[NaN NaN],{'MidBin', @nanmean, @tools.math.stat.rstd,@numel});
    By = timeSeries.bin.binningFast([Obj.JD, Y(:,ISrc)], Args.BinSize,[NaN NaN],{'MidBin', @nanmean, @tools.math.stat.rstd,@numel});
    Flag = Bx(:,4)>3 & By(:,4)>3;
    H = Obj.designMatrixPM('JD',Bx(Flag,1));
    DeltaX(ISrc) = std(Bx(Flag,2) - H*PMX(:,ISrc));
    DeltaY(ISrc) = std(By(Flag,2) - H*PMY(:,ISrc));
    Nep(ISrc) =median(Bx(Flag,4));
    
end

EtaX=  StdPrcX./sqrt(Nep)./(DeltaX*0.4*1000);
EtaY=  StdPrcY./sqrt(Nep)./(DeltaY*0.4*1000);



figure;
plot(StdPrcX./sqrt(Nep),DeltaX*0.4*1000,'.')
xlabel('$\sigma_x/\sqrt{N}$ [mas]','interpreter','latex')
ylabel('$\bar{\Delta}_x$ [mas]','interpreter','latex')
xlim([0,50]);
ylim([0,50]);
figure;
plot(StdPrcY./sqrt(Nep),DeltaY*0.4*1000,'.')
xlabel('$\sigma_y/\sqrt{N}$ [mas]','interpreter','latex')
ylabel('$\bar{\Delta}_y$ [mas]','interpreter','latex')
xlim([0,50]);
ylim([0,50]);

figure;

plot(mean(Mag,'omitnan'), EtaX,'.','DisplayName','$\eta_x$')
hold on;
plot(mean(Mag,'omitnan'), EtaY,'.','DisplayName','$\eta_y$')
xlabel('I')
legend('interpreter','latex');
figure;
h= histogram(EtaY,50,'DisplayName','$\eta_y$');
hold on;
histogram(EtaX,'BinEdges',h.BinEdges,'DisplayName','$\eta_x$')
legend('interpreter','latex');
%x= CM.MS.Data.X;
%y= CM.MS.Data.Y;
%mag = CM.MS.Data.MAG_PSF;








end