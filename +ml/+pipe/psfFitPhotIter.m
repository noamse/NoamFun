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



% Forced mode:
% The user proived information about sources positions. Magniute/SNR values of each source is
% optional
% if the user want to keep the same order - make indexing column
% waiting list - the sources which did not fitted.
% generate new catalog with the same order as forcedCat.
%
% loop:
%   run findsources for "waiting list"
%   remove SNR>thresh from "waiting list" write to xyforced 
%   run psfFitPhot with xy forced 
%   
%
% after loop: 
%   ask user for additional 'blind' iteration 
%   mark 'waiting list' in the catalogs. 

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

xy= Args.forcedCat.getXY;
IndexInRef = (1:numel(xy(:,1)))';

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

Im.CatData = AstroCatalog;
for Iiter = 1:1:Niter
%     if Iiter==1 && Args.UseAstroImageCat
%         
%         flag = ~any(isnan(Im.CatData.getXY),2);
%         
%         Im.CatData.Catalog = Im.CatData.Catalog(flag,:);
%         xy = Im.CatData.getXY;
%         Im.CatData=AstroCatalog;
%         Im = imProc.sources.findSources(Im.copy(),'Psf',Im.PSF,'Threshold',vecSNR(Iiter),'ForcedList',xy );
%         Im.CatData.Catalog = Im.CatData.Catalog(Im.CatData.getCol('SN_1')>vecSNR(Iiter),:);
%     else 
%         Im.CatData
%         Im = imProc.sources.findSources(Im,'Psf',Im.PSF,'Threshold',vecSNR(Iiter),'CreateNewObj',true);
%     end

    % No Threshold for detection - we want to get result from all.
    Im = imProc.sources.findSources(Im,'Psf',Im.PSF,'Threshold',vecSNR(Iiter),'OnlyForced',true,'ForcedList',xy );
    
    %Check threshold 
    SN = Im.CatData.getCol('SN_1');
    flagsn = SN>=vecSNR(Iiter);
    xytemp= xy(flagsn,:);
    xy = xy(~flagsn,:);
    indextemp =IndexInRef(flagsn);
    %indexInRefTemp = IndexInRef(flagsn);
    Im.CatData.Catalog = double(Im.CatData.Catalog);
    Im.CatData.Catalog = Im.CatData.Catalog(flagsn,:);
    
    % run psfFitPhot for the selected sources 
    [Im,res] = imProc.sources.psfFitPhot(Im,'XY',xytemp,'PSF',Im.PSF,'HalfSize',floor(numel(Im.PSF(:,1))/2),Args.psfFitPhotArgs{:});
    %Remove sources from image
    SrcCat = Im.CatData.getCol({'X','Y','FLUX_PSF'});
    flagnan = ~any(isnan(SrcCat),2);
    S = imUtil.art.injectSources(Im.sizeImage,SrcCat(flagnan,:),Im.PSF,Args.injectSourcesArgs{:});
    Im = Im- S;
    %SrcCat = [Im.CatData.getXY,Im.CatData.getCol('FLUX_PSF')];
    %S = imUtil.art.injectSources(Im.sizeImage,SrcCat(flagnan,:),PSF,'RecenterPSF',Args.RecenterPSF);
    
    
    %read catalog 
    Im.astroImage2AstroCatalog;
    Im.CatData.insertCol(indextemp,numel(Im.CatData.ColNames)+1,'IterNum');
    Cat(Iiter)= Im.astroImage2AstroCatalog;
    
    Res(Iiter)=res;
    Im.CatData=AstroCatalog;
end