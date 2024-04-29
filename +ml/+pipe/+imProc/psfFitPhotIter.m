function [Cat,Res,Im]=  psfFitPhotIter(Im,Args)


arguments
   Im;
   Args.XY =[];
   Args.PSF=[];
   Args.MAG=[];
   Args.NRefMagBin=2;
   Args.FitRadius = 3;
   Args.HalfSize = 8;
   Args.UseSourceNoise = true;
   Args.PSFfitMaxIter = 30;
   Args.PSFfitConvThresh = 1e-4;
   Args.RecenterPSF=false;
   Args.ReCalcBack=true;
end


if isempty(Args.XY)
    XY = Im.CatData.getXY;
else
    XY = Args.XY;
end

if isempty(Args.MAG)
    
    ColMag = colnameDict2ind(Im.CatData, Im.CatData.DefNamesMag);
    MAG  = getCol(Im.CatData, ColMag);
else
    MAG = Args.MAG;
end

if isempty(Args.PSF)
    PSF = Im.PSF;
else
    PSF=Args.PSF;
end
    
[~, ~, loc, N] = ut.calc_bin_fun(MAG, XY(:,1),'Nbins',Args.NRefMagBin);

if Args.NRefMagBin<2
    N=1;
    loc= ones(size(MAG));
end
Cat=AstroCatalog;
%Res=[];
for Ibin = 1:numel(N)
    flag_bin = loc == Ibin;
    if sum(flag_bin)==0
        continue;
    end
        
    if Args.ReCalcBack
        Im = imProc.background.background(Im,'ReCalcBack',Args.ReCalcBack);
    end
     
    Im= imProc.sources.findSources(Im,'Psf',Im.PSF,'Threshold',5,'OnlyForced',true,'ForcedList',[XY(flag_bin,1),XY(flag_bin,2)] );
    Im.CatData.Catalog= double(Im.CatData.Catalog);
    Im.CatData.insertCol(double([XY(flag_bin,1),XY(flag_bin,2),MAG(flag_bin),Ibin.*ones(size(XY(flag_bin,1)))]),...
                                        Inf,...
                                        {'RefX','RefY','RefMag','Niter'},...
                                        {'pix',    'pix',   'mag',''});

    [Im,res] = ml.pipe.psfFitPhot(Im,'XY',[XY(flag_bin,1),XY(flag_bin,2)],'FitRadius',Args.FitRadius,'HalfSize',Args.HalfSize,'ColSN','SN_1',...
        'psfPhotCubeArgs',{'UseSourceNoise',Args.UseSourceNoise});
    SrcCat = Im.CatData.getCol({'X','Y','FLUX_PSF'});
    
    flagnan = ~any(isnan(SrcCat),2);
    S = imUtil.art.injectSources(Im.sizeImage,SrcCat(flagnan,:),PSF,'RecenterPSF',Args.RecenterPSF);
    Im.Image = Im.Image- S;
    Cat(Ibin)= Im.astroImage2AstroCatalog;
    Res(Ibin)=res;
    Im.CatData=AstroCatalog;
end

Cat = Cat.merge;

end
