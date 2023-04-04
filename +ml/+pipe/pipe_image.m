function AstCat = pipe_image(ImagePath,I,Args)


arguments
    ImagePath ;
    I = 1
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
    
    Args.AstCatSavePath= '/data1/noamse/KMT/data/AstCats/';
    Args.FileName = 'AstCat_'
    Args.SaveFile = false;
    Args.HalfSize = 6;
    Args.mexCutout logical = true;
    Args.FitRadius = 3;
    Args.UseSourceNoise = 'all';
    Args.fitPSFKernelModel ='mtd';
    %Args.RefXY = [];
    Args.PSFfitmaxStep = 0.6;
    Args.PSFfitMaxIter = 50;
    Args.PSFfitConvThresh = 1e-4;
    %Args.Thresh1= 25;
    %Args.Thresh2= 15;
    %Args.SNRThresh = [25,15];
    Args.SNRforPSFConstruct = [];
    %Args.NeighborDistThreshReverse  =15;
    Args.UseReverseIter = false;
    %Args.OnlyOgleSource = false;
    Args.OgleCat = [];
    %Args.OgleMatchRadius=3;
    %Args.findMeasureSourceUsePSF = false;
    Args.ReCalcBack = true;
    Args.ExtractWithRef = true;
    Args.NRefMagBin=  6;
    Args.FitWings= true;
    Args.FitRadiusKernel=5;
    Args.PSFSmallStep=1e-5;
    Args.UseKernelPSFPhotometry = false;
        %Args.findMeasureSourcesPsfFunPar = {[0.5;  1; 2;],[8,8;8,8;8,8]};
end


Im = AstroImage(ImagePath,'CCDSEC',Args.CCDSEC_im );
Im.Image = single(Im.Image);

%Im = imProc.sources.findMeasureSources(Im,'Threshold',Args.threshold_im,'RemoveBadSources',Args.FindMeasureRemoveBad);


Cat= AstroCatalog;
try
    if Args.ExtractWithRef
        
        [Cat] = ml.pipe.mextractorIterRefcat(Im,Args.OgleCat.copy(),'FitRadius',Args.FitRadius,'HalfSize'...
            ,Args.HalfSize,'PSFfitConvThresh',Args.PSFfitConvThresh,'PSFfitMaxIter',Args.PSFfitMaxIter...
            ,'SNRforPSFConstruct',Args.SNRforPSFConstruct...
            ,'NRefMagBin',Args.NRefMagBin,'FitWings',Args.FitWings...
            ,'fitPSFKernelModel',Args.fitPSFKernelModel,'FitRadiusKernel',Args.FitRadiusKernel,'PSFSmallStep',Args.PSFSmallStep,...
            'UseKernelPSFPhotometry',Args.UseKernelPSFPhotometry);
        
    else
        
        %{
        [Sx,Sy] =sizeImage(Im);
        flag_edge= Args.EdgeDist < Im.CatData.getCol('X1') &Im.CatData.getCol('X1')<Sx-Args.EdgeDist  ...
           &  Args.EdgeDist < Im.CatData.getCol('Y1') &Im.CatData.getCol('Y1')<Sy-Args.EdgeDist ;
        %Im.CatData.Catalog = Im.CatData.Catalog(flag_edge,:);
        %[Im] =imProc.psf.constructPSF(Im,'constructPSF_cutoutsArgs',{'MedianCubeSumRange',[0.8 4],'mexCutout',Args.mexCutout},'HalfSize',Args.HalfSize);
        
        [Im] =imProc.psf.constructPSF(Im,'constructPSF_cutoutsArgs',{'MedianCubeSumRange',[0.8 2],'CubeSumRange',[0.8 2],'psf_zeroConvergeArgs',{'Radius',Args.HalfSize}},'HalfSize',Args.HalfSize);
        if isempty(Args.RefXY)
            [~,Im] = imProc.sources.psfFitPhot(Im,'FitRadius',Args.FitRadius,'HalfSize',Args.HalfSize,'psfPhotCubeArgs',{'ConvThresh',Args.PSFfitConvThresh,'MaxIter',Args.PSFfitMaxIter ,'UseSourceNoise',Args.UseSourceNoise});
        else
            Im.CatData=AstroCatalog({Args.RefXY},'ColNames',{'Xref','Yref'});
            [Res,Im] = imProc.sources.psfFitPhot(Im,'XY',Args.RefXY,'FitRadius',Args.FitRadius,'HalfSize',Args.HalfSize,'psfPhotCubeArgs',{'ConvThresh',Args.PSFfitConvThresh,'MaxIter',Args.PSFfitMaxIter,'UseSourceNoise',Args.UseSourceNoise,'MaxStep',Args.PSFfitmaxStep});
        end
        Im.CatData.deleteCol(Args.Cols2Delete);
        %}
        [Cat] = mextractorIter(Im,'FitRadius',Args.FitRadius,'HalfSize'...
            ,Args.HalfSize,'PSFfitConvThresh',Args.PSFfitConvThresh,'PSFfitMaxIter',Args.PSFfitMaxIter...
            ,'UseSourceNoise',Args.UseSourceNoise,'PSFfitMaxStep',Args.PSFfitmaxStep,...
            'SNRThresh',Args.SNRThresh,'SNRforPSFConstruct',Args.SNRforPSFConstruct...
            ,'MinNeighborDist',Args.MinNeighborDist,'findMeasureSourceUsePSF',Args.findMeasureSourceUsePSF,...
            'findMeasureSourcesPsfFunPar',Args.findMeasureSourcesPsfFunPar);
        
        
        if Args.UseReverseIter
            [Cat] = mextractorIterReverse(Cat,Im,'FitRadius',Args.FitRadius,...
                'HalfSize',Args.HalfSize,'PSFfitConvThresh',Args.PSFfitConvThresh,'PSFfitMaxIter',Args.PSFfitMaxIter...
                ,'UseSourceNoise',Args.UseSourceNoise,'PSFfitMaxStep',Args.PSFfitmaxStep...
                ,'NeighborDistThresh',Args.NeighborDistThreshReverse);
            
        end
        
        if Args.OnlyOgleSource
            Resultm1 = imProc.match.matchReturnIndices(Cat,Args.OgleCat,'Radius',Args.OgleMatchRadius);
            %Result_og_match = imProc.match.matchReturnIndices(Cat,Args.OgleCat,'Radius',Args.OgleMatchRadius);
            
            
            matched_flag_ogle_cat= Resultm1.Obj1_IndInObj2(~isnan(Resultm1.Obj1_IndInObj2));
            matched_flag_ref_cat = Resultm1.Obj1_FlagNearest;
            xy_kmt = Cat.getCol({'X','Y'});
            xy_kmt = xy_kmt(matched_flag_ref_cat,:);
            xy_ogle = Args.OgleCat.getCol({'X','Y'});
            xy_ogle = xy_ogle(matched_flag_ogle_cat,:);
            [Result_aff,matched_pattern] = imProc.trans.fitPattern(xy_kmt,xy_ogle,'Scale',[0.8,1.2]...
                ,'RangeX',[-7,7],'RangeY',[-7,7],'StepX',0.05,'StepY',0.05,'MaxMethod','max1','SearchRadius',Args.OgleMatchRadius,'Flip',[1 1]);
            [NewX,NewY]=imUtil.cat.affine2d_transformation([Args.OgleCat.getCol('X'),Args.OgleCat.getCol('Y')],Result_aff.Sol.AffineTran{1},'+'...
                ,'ColX',1,'ColY',2);
            OgleCat=Args.OgleCat.copy();
            OgleCat.Catalog(:,OgleCat.colname2ind({'X','Y'})) = [NewX,NewY];
            Resultm2 = imProc.match.matchReturnIndices(Cat,OgleCat,'Radius',Args.OgleMatchRadius);
            matched_flag_ref_cat = Resultm2.Obj1_FlagNearest;
            Cat.Catalog = Cat.Catalog(matched_flag_ref_cat ,:);
        end
    end
    
    
    
    
    
    if Cat.isemptyCatalog
        AstCat=AstroCatalog;
        AstCat.JD = Im.HeaderData.Key.JD;
        AstCat.UserData.bad_image= true;
        AstCat.UserData.FilePath = ImagePath;

        if Args.SaveFile
        disp([num2str(I) ' is empty catalog'])
        save([Args.AstCatSavePath Args.FileName num2str(I) '.mat'],'AstCat');
        end
        return 
    end

    AstCat= Cat.copy();
    AstCat.deleteCol(Args.Cols2Delete);
    if Args.ExtractWithRef
        AstCat.sortrows(AstCat(1).colname2ind('RefY'));
    else
        AstCat.sortrows(AstCat(1).colname2ind('Y'));
    end
    
    %D = sqrt((AstCat.getCol('Y') - AstCat.getCol('Y')').^2 ...
    %    +(AstCat.getCol('X') - AstCat.getCol('X')').^2);
    %flag_dist = sum(D<Args.MinNeighborDist,2)==1;
    %flag=flag_dist &flag_edge;
    
    %MAG_PSF = AstCat.getCol('MAG_PSF');
    %PSF_CHI2DOF= AstCat.getCol('PSF_CHI2DOF');
    %fun_prctl = @(x) prctile(x,Args.prctile_th );
    
    %[xmid, ymid, ~,~] =  ut.calc_bin_fun(MAG_PSF,PSF_CHI2DOF,'Nbins',Args.Nbin_chi2dof,'fun',fun_prctl);
    %interp_w = interp1(xmid,ymid,MAG_PSF,'nearest');
    
    
    AstCat.insertCol(Im.PSFData.fwhm*ones(size(AstCat.getCol(1))),1,'fwhm');
    Lat = convert.dms2angle(Im.HeaderData.Key.LATITUDE,'rad');
    secz = str2double(Im.HeaderData.Key.SECZ);
    HA = convert.hour_str2frac(Im.HeaderData.Key.HA)*2*pi;
    Dec = convert.dms2angle(Im.HeaderData.Key.DEC);
    cospa = cos(Dec).*sin(Lat) - sin(Dec).*cos(Lat).*cos(HA);
    sinpa = sin(HA).*cos(Lat);
    pa=atan2(sinpa,cospa);
    %pa = atan(sin(HA)./(tan(Lat).*cos(Dec) - sin(Dec).*cos(HA)));
    AstCat.insertCol(pa*ones(size(AstCat.getCol(1))),1,'pa');
    AstCat.insertCol(secz*ones(size(AstCat.getCol(1))),1,'secz');
    %AstCat.insertCol(double(Res.ConvergeFlag'),1,'Convg_flag');
    AstCat.JD = Im.HeaderData.Key.JD;
    AstCat.UserData.bad_image= false;
    AstCat.UserData.FilePath = ImagePath;
    
catch
    
    AstCat=AstroCatalog;
    AstCat.JD = Im.HeaderData.Key.JD;
    AstCat.UserData.bad_image= true;
    AstCat.UserData.FilePath = ImagePath;
    disp(['image ' num2str(I) ' , error while generate AstCat']);
end
clear Im;

if Args.SaveFile
    if (AstCat.isemptyCatalog)
        disp([num2str(I) ' is empty catalog'])
    end
    save([Args.AstCatSavePath Args.FileName num2str(I) '.mat'],'AstCat');
end





end