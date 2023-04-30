function [Cat,Im,Res] = psfFitPhotIter(ImOrg,Args)
% This function perform a multi-iteration psf photometry. 
% In each iteration, the function perform a psf photomtery for a subset of
% sources and remove them. 
% 
%
%

arguments
    
    ImOrg;
    Args.UseAstroImageCat = true
    Args.forcedCat =[];
    Args.reportNonDetection = false; 
    Args.vecSNR=5;
    Args.vecMag = [];
    Args.MagColName =AstroCatalog.DefNamesMag;
    Args.newImage =true;
    Args.snrBinNum = 3;
    Args.psfFitPhotArgs ={};
    Args.injectSourcesArgs= {};
end


if Args.newImage 
    Im = ImOrg.copy();
else
    Im = ImOrg;
end

if numel(Args.vecSNR)==1
    vecSNR = Args.vecSNR.*ones(Args.snrBinNum,1);
else
    vecSNR =  Args.vecSNR ;
end

Niter = numel(vecSNR);

% if ~isempty(Args.vecMag)
%     if ~isempty(Args.forcedCat)
%         ColMag = colnameDict2ind(Im.CatData, Args.MagColName);
%         MAG  = getCol(Args.forcedCat, ColMag);
%     else
%         ColMag = colnameDict2ind(Im.CatData, Args.MagColName);
%         MAG  = getCol(Im.CatData, ColMag);
%         
%     end
%     Niter = numel(Args.vecMag);
%     IterTreshold = 'mag';
% end
% 


for Iiter = 1:1:Niter
    if Iiter==1 && Args.UseAstroImageCat
        
        flag = ~any(isnan(Im.CatData.getXY),2);
        
        Im.CatData.Catalog = Im.CatData.Catalog(flag,:);
        xy = Im.CatData.getXY;
        Im.CatData=AstroCatalog;
        Im = imProc.sources.findSources(Im.copy(),'Psf',Im.PSF,'Threshold',vecSNR(Iiter),'ForcedList',xy );
        Im.CatData.Catalog = Im.CatData.Catalog(Im.CatData.getCol('SN_1')>vecSNR(Iiter),:);
    else 
        Im.CatData
        Im = imProc.sources.findSources(Im,'Psf',Im.PSF,'Threshold',vecSNR(Iiter),'CreateNewObj',true);
    end
    
        
    
    %if ~isempty(Args.forcedCat)
        
        %[Im,res] = imProc.sources.psfFitPhot(Im,'XY',[XY(flag_bin,1),XY(flag_bin,2)],'FitRadius',Args.FitRadius,'HalfSize',Args.HalfSize,...
        %    'psfPhotCubeArgs',{'ConvThresh',Args.PSFfitConvThresh,'MaxIter',Args.PSFfitMaxIter ,'UseSourceNoise',Args.UseSourceNoise});
    %    [Im,res] = imProc.sources.psfFitPhot(Im,'XY',[XY(flag_bin,1),XY(flag_bin,2)],Args.psfFitPhotArgs{:});
        
    %end
    
    Im.CatData.Catalog = double(Im.CatData.Catalog);
    [Im,res] = imProc.sources.psfFitPhot(Im,'XY',Im.CatData.getXY,'PSF',Im.PSF,'HalfSize',floor(numel(Im.PSF(:,1))/2),Args.psfFitPhotArgs{:});
    SrcCat = Im.CatData.getCol({'X','Y','FLUX_PSF'});
    %SrcCat = [Im.CatData.getXY,Im.CatData.getCol('FLUX_PSF')];
    
    flagnan = ~any(isnan(SrcCat),2);
    %S = imUtil.art.injectSources(Im.sizeImage,SrcCat(flagnan,:),PSF,'RecenterPSF',Args.RecenterPSF);
    S = imUtil.art.injectSources(Im.sizeImage,SrcCat(flagnan,:),Im.PSF,Args.injectSourcesArgs{:});
    
    Im = Im- S;
    Cat(Iiter)= Im.astroImage2AstroCatalog;
    Res(Iiter)=res;
    Im.CatData=AstroCatalog;
end