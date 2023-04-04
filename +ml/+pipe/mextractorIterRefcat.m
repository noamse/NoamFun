function [Cat,Res] = mextractorIterRefcat(Im,RefCat,Args)
% This function extract the reference catalog from an image.







arguments
    Im;
    RefCat;
    Args.SNRThresh= [100,50,20,5];
    Args.SNRforPSFConstruct = []
    Args.FindMeasureRemoveBad =true;
    Args.CCDSEC_im = [400,800,400,800];
    Args.Cols2Delete=  {'X1','Y1','X2','Y2','XY','FLUXERR_APER_1'...
        ,'FLUXERR_APER_2','FLUXERR_APER_3','FLUXERR__1','FLUXERR__2'...
        ,'FLUX_APER_3','APER_AREA_1','APER_AREA_2','APER_AREA_3','SN_1',...
        'SN_2','SN_3','SN_4','SN_5','FLUX_CONV_1','FLUX_CONV_2','FLUX_CONV_3'...
        ,'FLUX_CONV_4','FLUX_CONV_5','FLUX_APER_1','FLUX_APER_2','FLUX_APER_3',...
        'MAGERR_APER_1','MAGERR_APER_2','MAGERR_APER_3','MAG_CONV_1',...
        'MAG_CONV_2','MAG_CONV_3','MAG_CONV_4','MAG_CONV_5','MAGERR_CONV_1',...
        'MAGERR_CONV_2','MAGERR_CONV_3','MAGERR_CONV_4','MAGERR_CONV_5',...
        'MAG_APER_1','MAG_APER_2','MAG_APER_3','XPEAK','YPEAK','BACKMAG_ANNULUS'...
        ,'TEMP_ID','BACK_IM','VAR_IM','BACK_ANNULUS','STD_ANNULUS'};
    
    Args.HalfSize = 8;
    Args.mexCutout logical = true;
    Args.FitRadius = 3;
    Args.EdgeDist = 15;
    Args.UseSourceNoise = 'all';
    Args.PSFfitMaxStep = 0.6;
    Args.PSFfitMaxIter = 50;
    Args.PSFfitConvThresh = 1e-4;
    Args.FitRadiusKernel =5;
    Args.InerRadiusKernel = 3
    Args.FitWings= true;
    Args.fitPSFKernelModel = 'mtd';
    Args.constructPSFSmoothWings= false;
    Args.RecenterPSF =false;
    Args.findMeasureSourcesPsfFunPar=  {[0.5; 1.0; 1;]};
    Args.findMeasureSourceUsePSF = false;
    Args.ReCalcBack = true;
    Args.MatchRadius = 4;
    Args.MatchRadiusPattern = 1;
    Args.NRefMagBin=5;
    Args.PSFSmallStep= 1e-3;
    Args.UseKernelPSFPhotometry = false;
    
end
    

if isempty(Args.SNRforPSFConstruct)
    Args.SNRforPSFConstruct = Args.SNRThresh(1);
end
% Naive extraction from the the image for matching and PSF construction

Im = imProc.sources.findMeasureSources(Im,'Threshold',Args.SNRforPSFConstruct,...
    'RemoveBadSources',false,'ReCalcBack',true,'PsfFunPar',Args.findMeasureSourcesPsfFunPar);
[Im] =imProc.psf.constructPSF(Im,'constructPSF_cutoutsArgs',{'MedianCubeSumRange',[0.8 4]...
    ,'CubeSumRange',[0.8 4],'SmoothWings',Args.constructPSFSmoothWings,...
    'psf_zeroConvergeArgs',{'Radius',Args.HalfSize}},'HalfSize',Args.HalfSize);

[Im] = imProc.sources.psfFitPhot(Im,'FitRadius',Args.FitRadius,'HalfSize',Args.HalfSize,...
    'psfPhotCubeArgs',{'ConvThresh',Args.PSFfitConvThresh,'MaxIter',Args.PSFfitMaxIter ,'UseSourceNoise',Args.UseSourceNoise,'SmallStep',Args.PSFSmallStep});

[~,Kmin] = ml.pipe.psf.fitPSFKernel(Im.PSF,'model',Args.fitPSFKernelModel,'FitRadius',Args.FitRadiusKernel...
    ,'FitWings',Args.FitWings,'InerRadius',Args.InerRadiusKernel);
if Args.UseKernelPSFPhotometry
    Im.PSFData.Data = Kmin;
end
% Match reference catalog and fit affine transformation

RefCatBright = RefCat.copy();
ImagClip = RefCatBright.getCol('I');
flag_mag = ImagClip<median(ImagClip,'omitnan');
RefCatBright.Catalog = RefCatBright.Catalog(flag_mag,:);
Resultm1 = imProc.match.matchReturnIndices(Im.CatData,RefCatBright,'Radius',Args.MatchRadius );
matched_flag_ref_cat= Resultm1.Obj1_IndInObj2(~isnan(Resultm1.Obj1_IndInObj2));
matched_flag_im_cat = Resultm1.Obj1_FlagNearest;
if isempty(matched_flag_ref_cat) || sum(matched_flag_im_cat)<1
    Res=[];
    Cat = AstroCatalog;
    return;
end
xy_im = Im.CatData.getCol({'X1','Y1'});
xy_im = xy_im(matched_flag_im_cat,:);
xy_ref = RefCatBright.getCol({'X','Y'});
xy_ref = xy_ref(matched_flag_ref_cat,:);


    
[Result_aff] = imProc.trans.fitPattern(xy_im,xy_ref,'Scale',[0.8,1.2]...
    ,'RangeX',[-15,15],'RangeY',[-15,15],'StepX',0.05,'StepY',0.05,'MaxMethod','max1','SearchRadius',Args.MatchRadiusPattern,'Flip',[1 1]);
[NewX,NewY]=imUtil.cat.affine2d_transformation([RefCat.getCol('X'),RefCat.getCol('Y')],Result_aff.Sol.AffineTran{1},'+'...
    ,'ColX',1,'ColY',2);

RefCat.Catalog(:,RefCat.colname2ind({'X','Y'})) = [NewX,NewY];    
% Filter reference sources. 
X = RefCat.getCol('X');
Y = RefCat.getCol('Y');
Imag = RefCat.getCol('I');
[Szim1,Szim2] =Im.sizeImage;
flag_out_of_bound= X>0 & Y>0  & X<Szim1& Y<Szim2;

if sum(flag_out_of_bound)<0.5*numel(flag_out_of_bound)
    Res=[];
    Cat = AstroCatalog;
    return;
end
X = X(flag_out_of_bound);
Y = Y(flag_out_of_bound);

Imag = Imag(flag_out_of_bound);
%D = sqrt((X-X').^2 + (Y-Y').^2);
%B = timeseries.binningFast([RefCat.getCol('I'),min(D)'], 2,[NaN NaN],{'MidBin', @median});

if Args.NRefMagBin ==1
    Im.CatData=AstroCatalog({[X,Y,Imag,ones(size(X))]},'ColNames',{'RefX','RefY','RefMag','Niter'});
    [Im,res] = imProc.sources.psfFitPhot(Im,'XY',[X,Y],'FitRadius',Args.FitRadius,'HalfSize',Args.HalfSize,...
        'psfPhotCubeArgs',{'ConvThresh',Args.PSFfitConvThresh,'MaxIter',Args.PSFfitMaxIter ,'UseSourceNoise',Args.UseSourceNoise});
    Cat= Im.astroImage2AstroCatalog;
    Res=res;
    return
end


[Cat,Res]=  ml.pipe.imProc.psfFitPhotIter(Im.copy(),'XY',[X,Y],'PSF',Kmin,'MAG',Imag,'NRefMagBin',Args.NRefMagBin,'FitRadius',Args.FitRadius,...
    'HalfSize',Args.HalfSize,'UseSourceNoise',Args.UseSourceNoise,'PSFfitMaxIter',Args.PSFfitMaxIter,'PSFfitConvThresh',Args.PSFfitConvThresh,...
    'RecenterPSF',Args.RecenterPSF,'ReCalcBack',Args.ReCalcBack);

end
%{





if Args.findMeasureSourceUsePSF
    psf = repmat(Im.PSFData.Data,1,1,numel(Args.findMeasureSourcesPsfFunPar{1}));
    Im = imProc.sources.findMeasureSources(Im,'Threshold',Args.SNRforPSFConstruct...
        ,'RemoveBadSources',false,'ReCalcBack',Args.ReCalcBack,'Psf',psf);
else
    Im = imProc.sources.findMeasureSources(Im,'Threshold',Args.SNRforPSFConstruct,...
        'RemoveBadSources',false,'ReCalcBack',Args.ReCalcBack,'PsfFunPar',Args.findMeasureSourcesPsfFunPar);
end
[Im] = imProc.sources.psfFitPhot(Im,'FitRadius',Args.FitRadius,'HalfSize',Args.HalfSize,...
    'psfPhotCubeArgs',{'ConvThresh',Args.PSFfitConvThresh,'MaxIter',Args.PSFfitMaxIter ,'UseSourceNoise',Args.UseSourceNoise});

Cat= AstroCatalog;
Cat(1)= Im.astroImage2AstroCatalog;
if numel(Args.SNRThresh)==1
    return;
end
for IndSNR = 2:numel(Args.SNRThresh)
    SrcCat = Im.CatData.getCol({'X','Y','FLUX_PSF'});
    SrcCat= SrcCat(all(~isnan(SrcCat),2),:);
    S = injectSources(Im.sizeImage,SrcCat,Im.PSF,'RecenterPSF',Args.RecenterPSF);
    %Im = imProc.sources.findMeasureSources(Im,'Threshold',Args.SNRThresh(IndSNR),'RemoveBadSources',false,'ReCalcBack',true);
    Im = Im- S;
    Im.CatData=AstroCatalog;
    
    if Args.findMeasureSourceUsePSF
        Im = imProc.sources.findMeasureSources(Im,'Threshold',Args.SNRThresh(IndSNR),'RemoveBadSources',false,'ReCalcBack',Args.ReCalcBack,'Psf',psf);
    else
        Im = imProc.sources.findMeasureSources(Im,'Threshold',Args.SNRThresh(IndSNR),...
            'RemoveBadSources',false,'ReCalcBack',true,'PsfFunPar',Args.findMeasureSourcesPsfFunPar);
    end
    Im = imProc.sources.psfFitPhot(Im,'FitRadius',Args.FitRadius,'HalfSize',Args.HalfSize,...
        'psfPhotCubeArgs',{'ConvThresh',Args.PSFfitConvThresh,'MaxIter',Args.PSFfitMaxIter ,'UseSourceNoise',Args.UseSourceNoise});
    Cat(IndSNR)= Im.astroImage2AstroCatalog;
end

Cat = Cat.merge;
x = Cat.getCol('X');
y = Cat.getCol('Y');

D = sqrt((x-x').^2 + (y-y').^2);
D(logical(eye(size(D))))=nan;
flag = min(D)>=Args.MinNeighborDist;
Cat.Catalog= Cat.Catalog(flag,:);

end

    
end








end
%}