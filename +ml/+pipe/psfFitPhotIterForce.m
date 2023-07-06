function [Result,AISub] = psfFitPhotIterForce(AI,RefCat,Args)
% Perform a multi-iteration psf forced photometry. 
% In each iteration, the function perform a forced photomtery for a subset of
% sources and remove them. 
% 
%
%



arguments
    
    AI;
    RefCat;
    Args.reportNonDetection = false; 
    Args.SNThreshold=5;
    Args.MagThreshold = [];
    Args.MagColName =AstroCatalog.DefNamesMag;
    Args.additionalIteration = false;
    Args.additionalIterationSNThreshold= 5;
    Args.newImage =true;
    Args.Niter = 3;
    Args.MaxDistFromRef =[];
    Args.ReCalcBack = true;
    Args.OutType    = 'astroimage'; % astroimage or astrocatalog
    Args.backgroundArgs={};
    Args.psfFitPhotArgs ={'psfPhotCubeArgs',{'MaxStep',0.2,'MaxIter',20,'SmallStep',5e-5,'FitRadius',1.5}};
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
    AISub = AI.copy();
else
    AISub = AI;
end

if numel(Args.SNThreshold)==1
    Threshold = Args.SNThreshold.*ones(Args.Niter,1);
else
    Threshold =  Args.SNThreshold ;
end


if ~isempty(Args.MagThreshold)
    MagColInd = RefCat.colname2ind(Args.MagColName);
    if all(isnan(MagColInd))
        error('Can not find MAG col in reference catalog');
    end
    refMag = RefCat.getCol(MagColInd(~isnan(MagColInd)));
end

XY= RefCat.getXY;
IndexInRef = (1:numel(XY(:,1)))';
if isempty(Args.MagThreshold)
    Niter = numel(Threshold);
else
    Niter = numel(Args.MagThreshold);
end
AISub.CatData = AstroCatalog;
[Imsz1,Imsz2] =AISub.sizeImage;

for Iiter = 1:1:Niter
    % No Threshold for detection - we want to get result from all.
    if Args.ReCalcBack
        AISub = imProc.background.background(AISub,'ReCalcBack',Args.ReCalcBack,Args.backgroundArgs{:});
    end
    if isempty(Args.MagThreshold)
        
        AISub = imProc.sources.findSources(AISub,'Psf',AISub.PSF,'Threshold',Threshold(Iiter),'OnlyForced',true,'ForcedList',XY );
        
    %Check threshold 
        SN = AISub.CatData.getCol('SN_1');
        flagsn = SN>=Threshold(Iiter);
        XYtemp= XY(flagsn,:);
        XY = XY(~flagsn,:);
        indextemp =IndexInRef(flagsn);
    %indexInRefTemp = IndexInRef(flagsn);
        AISub.CatData.Catalog = double(AISub.CatData.Catalog);
        AISub.CatData.Catalog = AISub.CatData.Catalog(flagsn,:);
    else
        flagmag = refMag<= Args.MagThreshold(Iiter);
        refMagtemp = refMag(flagmag);
        refMag  = refMag(~flagmag);
        
        XYtemp= XY(flagmag,:);
        XY = XY(~flagmag,:);
        indextemp =IndexInRef(flagmag);
        %Im.CatData.Catalog = Im.CatData.Catalog(flagmag,:);
    end
    % run psfFitPhot for the selected sources 
    if ~isempty(XYtemp)
        AISub.CatData=AstroCatalog({[XYtemp(:,1),XYtemp(:,2),refMagtemp ,ones(size(refMagtemp)).*Iiter]},'ColNames',{'RefX','RefY','RefMag','Niter'},'ColUnits',{'pix','pix','',''});
        [AISub] = imProc.sources.psfFitPhot(AISub,'XY',XYtemp,'PSF',AISub.PSF,'ColSN',[],'HalfSize',floor(numel(AISub.PSF(:,1))/2),Args.psfFitPhotArgs{:});
        %Remove sources from image
        SrcCat = AISub.CatData.getCol({'X','Y','FLUX_PSF'});
        flagSrc = ~any(isnan(SrcCat),2);
        if ~isempty(Args.MaxDistFromRef)
            D = sqrt((AISub.CatData.getCol('X')- XYtemp(:,1)).^2 + (AISub.CatData.getCol('Y')- XYtemp(:,2)).^2 );
            flagSrc  = flagSrc & D<Args.MaxDistFromRef;
            AISub.CatData.Catalog(~flagSrc,:) = nan;
        end
        S = imUtil.art.injectSources([Imsz1,Imsz2],SrcCat(flagSrc,:),AISub.PSF,Args.injectSourcesArgs{:});
        AISub = AISub- S;

        
    end
        Cat(Iiter)= AISub.astroImage2AstroCatalog;
        AISub.CatData=AstroCatalog;
end


if Args.additionalIteration
    if Args.ReCalcBack
        AISub = imProc.background.background(AISub,'ReCalcBack',Args.ReCalcBack,Args.backgroundArgs{:});
    end

    AISub = imProc.sources.findSources(AISub,'Psf',AISub.PSF,'Threshold',Args.additionalIterationSNR );
    AISub.CatData.Catalog = double(AISub.CatData.Catalog);
    [AISub] = imProc.sources.psfFitPhot(AISub,'PSF',AISub.PSF,'HalfSize',floor(numel(AISub.PSF(:,1))/2),Args.psfFitPhotArgs{:});
    AISub.CatData= AstroCatalog({double([res.X, res.Y, res.Flux, res.Mag, res.Chi2./res.Dof,res.SNm])},...
                                    'ColNames',{'X',      'Y',      'FLUX_PSF',  'MAG_PSF', 'PSF_CHI2DOF','SN'},...
                                    'ColUnits',{'pix',    'pix',    '',          'mag',     '',''});

    AISub.CatData.insertCol([nan(numel(AISub.CatData.Catalog(:,1)),3),(Iiter+1).*ones(numel(AISub.CatData.Catalog(:,1)),2) ],Inf,{'RefX','RefY','RefMag','Niter'},{'pix','pix','',''});
    Cat(Iiter+1)= AISub.astroImage2AstroCatalog;
    
    
    AISub.CatData=AstroCatalog;

end




    Cat = Cat.merge;
    switch lower(Args.OutType)
        case 'astroimage'
            Result = AI;
            Result.CatData = Cat;

        case 'astrocatalog'
            Result = Cat;
        otherwise
            error('Unknown OutType option');
    end

end





%    Args.additionalIteration = false;
%    Args.IdditionalIterationSNR = 5;


%if Args.additionalIteration
%
%     Result = imProc.sources.findSources(Result,'Psf',Result.PSF,'Threshold',Args.additionalIterationSNR );
%     Result.CatData.Catalog = double(Result.CatData.Catalog);
%     [Result,res] = imProc.sources.psfFitPhot(Result,'PSF',Result.PSF,'HalfSize',floor(numel(Result.PSF(:,1))/2),Args.psfFitPhotArgs{:});
%     %Im.CatData= AstroCatalog({double([res.X, res.Y, res.Flux, res.Mag, res.Chi2./res.Dof,res.SNm])},...
%     %                                'ColNames',{'X',      'Y',      'FLUX_PSF',  'MAG_PSF', 'PSF_CHI2DOF','SN'},...
%     %                                'ColUnits',{'pix',    'pix',    '',          'mag',     '',''});
%
%     Result.CatData.insertCol((Iiter+1).*ones(numel(Result.CatData.Catalog(:,1)),2) ,Inf,{'Niter'},{''});
%     Cat(Iiter+1)= Result.astroImage2AstroCatalog;
%     Res(Iiter+1)=res;
%
%     Result.CatData=AstroCatalog;
%
% end
%




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

