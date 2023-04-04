function [ResultCat] = mextractorIterReverse(Cat,Im,Args)
% Recalculate the flux and position of sources in Cat.
%   The function go over the sources, and for each source runs psf
%   photometry after substracting the neightbors.

arguments
    Cat;
    Im;
    Args.NeighborDistThresh = 20;
    Args.FitRadius = 3;
    Args.HalfSize = 8;
    Args.mexCutout logical = true;
    Args.PSFfitMaxStep = 0.1;
    Args.PSFfitMaxIter = 50;
    Args.PSFfitConvThresh = 1e-4;
    Args.UseSourceNoise = 'all';
    Args.RecenterPSF = true;
    
end



NeightCutoutHalfSize = Args.NeighborDistThresh + 2*Args.HalfSize +2;
Nsrc= numel(Cat.Catalog(:,1));
x = Cat.getCol('X');
y = Cat.getCol('Y');

D = sqrt((x-x').^2 + (y-y').^2);
D(logical(eye(size(D))))=nan;

ResultCat= AstroCatalog([Nsrc,1]);
ImLoop = Im.copy();
Im.Image  = Im.Image - Im.Back;
%[Cube, RoundX, RoundY, X, Y] = imUtil.cut.image2cutouts(Im.Image, x, y, NeightCutoutHalfSize, 'mexCutout',Args.mexCutout , 'Circle',false);
for SrcInd = 1:Nsrc
    Neighbor_flag = D(:,SrcInd)<Args.NeighborDistThresh;
    SrcCatLoop = Cat.copy();
    if ~any(Neighbor_flag)
        
        ResultCat(SrcInd) = SrcCatLoop;
        ResultCat(SrcInd).Catalog =  ResultCat(SrcInd).Catalog(SrcInd,:);
        continue;
    end
    
    SrcCatLoop.Catalog = SrcCatLoop.Catalog(Neighbor_flag,:);
    S = injectSources(Im.sizeImage,SrcCatLoop.getCol({'X','Y','FLUX_PSF'}),Im.PSF,'RecenterPSF',Args.RecenterPSF);
    ImLoop.Image= Im.Image- S;
    
    ImLoop.CatData.Catalog = Cat.Catalog(SrcInd,:);
    ImLoop = imProc.sources.psfFitPhot(ImLoop,'XY',ImLoop.CatData.getCol({'X','Y'}),'FitRadius',Args.FitRadius,'HalfSize',Args.HalfSize,...
        'psfPhotCubeArgs',{'ConvThresh',Args.PSFfitConvThresh,'MaxIter',Args.PSFfitMaxIter ,'UseSourceNoise',Args.UseSourceNoise});
    ResultCat(SrcInd) = ImLoop.astroImage2AstroCatalog;
end
ResultCat = ResultCat.merge;