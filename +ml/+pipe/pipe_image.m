function AstCat = pipe_image(ImagePath,I,Args)


arguments
    ImagePath ;
    I = 1
    %Args.CCDSEC_im = [400,800,400,800];
    Args.CCDSEC_xd = 400;
    Args.CCDSEC_xu = 800;
    Args.CCDSEC_yd = 400;
    Args.CCDSEC_yu = 800;
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
    Args.MaxRefMagForPattern= [];
        %Args.findMeasureSourcesPsfFunPar = {[0.5;  1; 2;],[8,8;8,8;8,8]};
end


Im = AstroImage(ImagePath,'CCDSEC',[Args.CCDSEC_xd,Args.CCDSEC_xu,Args.CCDSEC_yd,Args.CCDSEC_yu]   );
Im.Image = single(Im.Image);

%Im = imProc.sources.findMeasureSources(Im,'Threshold',Args.threshold_im,'RemoveBadSources',Args.FindMeasureRemoveBad);


Cat= AstroCatalog;
try
    
        
   [Cat] = ml.pipe.mextractorIterRefcat(Im,Args.OgleCat.copy(),'FitRadius',Args.FitRadius,'HalfSize'...
        ,Args.HalfSize,'PSFfitConvThresh',Args.PSFfitConvThresh,'PSFfitmaxStep',Args.PSFfitmaxStep,'PSFfitMaxIter',Args.PSFfitMaxIter...
        ,'SNRforPSFConstruct',Args.SNRforPSFConstruct...
        ,'NRefMagBin',Args.NRefMagBin,'FitWings',Args.FitWings...
        ,'fitPSFKernelModel',Args.fitPSFKernelModel,'FitRadiusKernel',Args.FitRadiusKernel,'PSFSmallStep',Args.PSFSmallStep,...
        'UseKernelPSFPhotometry',Args.UseKernelPSFPhotometry,'ImagClip',Args.MaxRefMagForPattern);
       
    
    
    
    
    if Cat.isemptyCatalog
        AstCat=AstroCatalog;
        %AstCat.JD = Im.HeaderData.Key.JD;
        
        if isfield(Im.HeaderData.Key,'JD')
            AstCat.JD = Im.HeaderData.Key.JD;
        elseif isfield(Im.HeaderData.Key,'MIDJD')
            AstCat.JD = Im.HeaderData.Key.MIDJD;
        else
            disp('Did not find JD in header')
            AstCat.JD =0;
        end
    

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
    if isfield(Im.HeaderData.Key,'JD')
        AstCat.JD = Im.HeaderData.Key.JD;
    elseif isfield(Im.HeaderData.Key,'MIDJD')
        AstCat.JD = Im.HeaderData.Key.MIDJD;
    else
        disp('Did not find JD in header')
        AstCat.JD =0;
    end

    AstCat.UserData.bad_image= false;
    AstCat.UserData.FilePath = ImagePath;
    
catch
    
    AstCat=AstroCatalog;
    if isfield(Im.HeaderData.Key,'JD')
        AstCat.JD = Im.HeaderData.Key.JD;
    elseif isfield(Im.HeaderData.Key,'MIDJD')
        AstCat.JD = Im.HeaderData.Key.MIDJD;
    else
        disp('Did not find JD in header')
        AstCat.JD =0;
    end
    
    %AstCat.JD = Im.HeaderData.Key.MIDJD;
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