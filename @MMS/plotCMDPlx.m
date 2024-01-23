function plotCMDPlx(Obj,RefCat,Args)
arguments
    Obj;
    RefCat;
    Args.MaxMag = 17;
    Args.CloseAll = true;
   
end

if Args.CloseAll 
    close all;
end
figure; 
[Matched]   = Obj.matchToRefCat(RefCat);
Color = Matched.getCol('V-I');
Mag = Obj.medianFieldSource({'MAG_PSF'});
FlagMag = Mag<Args.MaxMag;
scatter(Color(FlagMag),Mag(FlagMag),[],abs(Obj.PMPlx(5,FlagMag)'),'filled')
set(gca,'YDir','reverse')
colorbar;



figure; 
plot(abs(Color(FlagMag)-median(Color(FlagMag),'omitnan')),abs(Obj.PMPlx(5,FlagMag)' ),'*');
xlabel('|Color-med(Color)|')
ylabel('|q| [mas]')