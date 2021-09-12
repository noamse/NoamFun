%{
--------------------------------------------------------------------------
    obs_run class                                                       class
    Description: Class to handle results from observations run from WFAST
              Each image in the obsevation run is supposedely point at the
              same coordinates.
              The class contains the calibration data, the images list and
              the resulted catalog from the analysis.
    Input  : null
    Output : null
    Tested : Matlab 2019b
    By : Noam Segev                    May 2021
 
    URL : http://weizmann.ac.il/home/eofek/matlab/
    Reliable: 2
--------------------------------------------------------------------------
%}

classdef obs_run < handle
    properties (SetAccess = public)
        Folder
        SIM
        ImagesPath
        ImagesType='h5z';
        im_h5opt = '/images';
        SavePath
        DirObj
        imageTrimCenter
        imageTrimSize = [500,500];
        CalibObj = load([getenv('DATA') '/WFAST/calibration/calibration_2021-05-02_WFAST_Balor.mat']);
        ZeroPoint=[];
        
        
        forced_astcat
        cut_img_thresh=30;
        full_img_thresh=120;
        Gaia_Cat
        astrometry_Res
        WCS
        objRA= 270.76162/180*pi;
        objDec = -29.83046/180*pi;
        objXY=[];
        PSF_zeros=[];
        Failed=[];
        log_file;
        current_image=[];
        currnet_ZeroPoint=[];
        current_PSF_zeros=[];
        current_astcat =[];
        current_failed=[];
        current_forced_astcat
        loaded_data=[];
        saved_dir
    end
    properties (Hidden = true)
        ImagesSort
        Name
        Source
        Reference
        Version
        %UserData
    end
    
    
    
    % Construction
    methods
        % Constructor for the observation run Class.
        function ObsC =obs_run(Folder)
            % ra and dec in radians
            ObsC.Folder = Folder;
            ObsC.DirObj = dir([ObsC.Folder '*.' ObsC.ImagesType]);
            ObsC.ImagesPath = strcat(ObsC.Folder,{ObsC.DirObj.name});
            
            
            
        end
        
        
        
        
        
    end
    
    % get/set
    methods
        function set.SavePath(ObsC,val)
            if isempty(val)
                splited_dir = split(ObsC.Folder,'/');
                ObsC.SavePath = ['/home/noamse/astro/WFAST/maxi_j1803/data/results/' ...
                    splited_dir{end-2} '_' splited_dir{end-1} '/'];
            end
            
        end
    end
    
    methods
        % functions
        function ObsC =load_image(ObsC,varargin)
            % Load image from directory
            InPar =inputParser;
            addOptional(InPar ,'ImageNum',5);
            parse(InPar,varargin{:});
            InPar = InPar.Results;
            
            
            
            ObsC.SIM=ut.sim.wfast_read2sim(ObsC.ImagesPath{InPar.ImageNum},'im_h5opt',ObsC.im_h5opt);
            ObsC.SIM.Im=ObsC.CalibObj.obj.input(ObsC.SIM.Im,'sum',cell2mat(getkey(ObsC.SIM,'NAXIS3')));
            ObsC.current_image = InPar.ImageNum;
            
            
            
            
            
        end
        
        
        function trimImage(ObsC,varargin)
            
            if isempty(ObsC.imageTrimCenter)
                ObsC.imageTrimCenter=round(ObsC.objXY);
            end
            
            if ~any(ObsC.objXY)
                disp('No coordinates to trim around')
            end
            ObsC.SIM.WCS=[]; % Solve bug in the WCS replication.
            ObsC.SIM=trim_image(ObsC.SIM,...
                [ObsC.imageTrimCenter(1) ObsC.imageTrimCenter(2)...
                ,ObsC.imageTrimSize(1),ObsC.imageTrimSize(1)],'SectionMethod','center');
        end
        
        
        
        function run_mextractor(ObsC,varargin)
            % Load image from directory
            InPar =inputParser;
            addOptional(InPar ,'Thresh',150);
            parse(InPar,varargin{:});
            InPar = InPar.Results;
            
            if isempty(ObsC.SIM)
                disp('No sim Obecjt in Observation Class')
            end
            ObsC.SIM= mextractor(ObsC.SIM,'AperBackErrFun',@nanstd,'AperBackFun',@nanmedian...
                ,'Thresh',InPar.Thresh,'FilterFindThresh',InPar.Thresh);
            
            
            
        end
        
        
        
        function solve_astrometry(ObsC,varargin)
            % Load image from directory
            RAD=180/pi;
            InPar =inputParser;
            addOptional(InPar ,'RefCatMagRange',[7,13]);
            addOptional(InPar ,'RCrad',1.5/RAD);
            addOptional(InPar ,'SearchRangeX',[-1500 1500]);
            addOptional(InPar ,'SearchRangeY',[-1500 1500]);
            addOptional(InPar ,'RA',[]);
            addOptional(InPar ,'Dec',[]);
            parse(InPar,varargin{:});
            InPar = InPar.Results;
            
            if isempty(ObsC.SIM)
                disp('No sim Obecjt in Observation Class')
                return
            end
            if isempty(ObsC.SIM.Cat)
                disp('Catalog is empty - calling obs_run.run_mextractor')
                ObsC= ObsC.run_mextractor;
            end
            SCALE = cell2mat(ObsC.SIM.getkey('SCALE'));
            
            if (isempty(InPar.RA)||isempty(InPar.Dec))
                [ObsC.astrometry_Res,ObsC.SIM]= astrometry(ObsC.SIM,'RA',cell2mat(getkey(ObsC.SIM,'RA_DEG'))/180*pi...
                    ,'DEC',cell2mat(getkey(ObsC.SIM,'DEC_DEG'))/180*pi,'SCALE',SCALE...
                    ,'SearchRangeX',InPar.SearchRangeX, 'SearchRangeY',InPar.SearchRangeY...
                    ,'RefCatMagRange',InPar.RefCatMagRange,'RCrad',InPar.RCrad);
            else
                [ObsC.astrometry_Res,ObsC.SIM]= astrometry(ObsC.SIM,'RA',InPar.RA...
                    ,'DEC',InPar.Dec,'SCALE',SCALE...
                    ,'SearchRangeX',InPar.SearchRangeX, 'SearchRangeY',InPar.SearchRangeY...
                    ,'RefCatMagRange',InPar.RefCatMagRange,'RCrad',InPar.RCrad);
            end
            ObsC.SIM=update_coordinates(ObsC.SIM);
            ObsC.WCS = ClassWCS.populate(ObsC.SIM);
            
        end
        
        function object_xy_pos(ObsC)
            if ~any([ObsC.objRA,ObsC.objDec])
                disp('No object coordinates')
            end
            
            
            ObsC.objXY = ut.coo2xy(ObsC.WCS,ObsC.objRA,ObsC.objDec);
            %ObsC.imageTrimCenter=round(ObsC.objXY);
        end
        
        
        
        
        function Gaia_cm(ObsC,varargin)
            RAD=180/pi;
            InPar =inputParser;
            addOptional(InPar ,'ObjAsCenter',true);
            addOptional(InPar ,'max_d_cone',3/RAD);
            %addOptional(InPar ,'min_SN',40);
            
            parse(InPar,varargin{:});
            InPar = InPar.Results;
            
            
            RA=ObsC.SIM.Cat(:,ObsC.SIM.Col.ALPHAWIN_J2000);
            Dec=ObsC.SIM.Cat(:,ObsC.SIM.Col.DELTAWIN_J2000);
            if InPar.ObjAsCenter
                medRA= ObsC.objRA;
                medDec= ObsC.objDec;
                
            else
                medRA = nanmedian(RA);
                medDec = nanmedian(Dec);
            end
            
            D       = celestial.coo.sphere_dist_fast(medRA,medDec,RA,Dec);
            %SN =
            ObsC.SIM.Cat=ObsC.SIM.Cat(D<InPar.max_d_cone,:);
            %gaiacat= catsHTM.sources_match('GAIADR2',S);
            ObsC.Gaia_Cat= catsHTM.sources_match('GAIADR2',ObsC.SIM);
        end
        
        
        function ObsC =upload_data(ObsC,varargin)
            % Load saved data struct to loaded_data
            InPar =inputParser;
            addOptional(InPar ,'ImageNum',1);
            addOptional(InPar ,'StrInFile','result');
            addOptional(InPar ,'DataName','st');
            parse(InPar,varargin{:});
            InPar = InPar.Results;
            
            a=load(ut.fullpath(ObsC.saved_dir,InPar.ImageNum,'IsFile',true));
            FieldName= fields(a);
            ObsC.loaded_data=a.(FieldName{1});
            
            
            
            
            
            
        end
        
        
        function save_current(ObsC,varargin)
            InPar =inputParser;
            addOptional(InPar ,'Field2Save',{'currnet_ZeroPoint','current_PSF_zeros'...,
                'current_astcat','current_forced_astcat','current_failed','current_image','objXY','objRA','objDec'...
                ,'astrometry_Res','Gaia_Cat'});
            
            parse(InPar,varargin{:});
            InPar = InPar.Results;
            st=[];
            for i = 1:numel(InPar.Field2Save)
                
                st.(InPar.Field2Save{i}) = ObsC.(InPar.Field2Save{i});
            end
            
            save([ObsC.SavePath 'result_image_' num2str(ObsC.current_image) '.mat'],'st','-v7.3')
            
            
        end
        
        
        function save_full(ObsC)
            
            save([ObsC.SavePath 'ObsC.mat'],'ObsC','-v7.3')
        end
        
        
        function ZeroPoint= fit_zp(ObsC)
            % Take the zero magnitude as the robust mean of
            magGaia = ObsC.loaded_data.Gaia_Cat.Cat(:,ObsC.loaded_data.Gaia_Cat.Col.Mag_G);
            MagRange = prctile(magGaia ,[20,50]);
            
            flagtop10 = magGaia >MagRange(1) &magGaia >MagRange(2);
            Mag = ObsC.loaded_data.current_astcat.Cat(:,ObsC.loaded_data.current_astcat.Col.MAG_PSF);
            magGaia = ObsC.loaded_data.Gaia_Cat.Cat(:,ObsC.loaded_data.Gaia_Cat.Col.Mag_G);
            ZeroPoint= nanmean((Mag(flagtop10)-magGaia(flagtop10))');
        end
        
        
        
        
        function forced_photometry(ObsC,varargin)
            InPar =inputParser;
            addOptional(InPar ,'WinPosFromForce',false);
            
            parse(InPar,varargin{:});
            InPar = InPar.Results;
            %ObsC = object_xy_pos(ObsC);
            
            S= mextractor(ObsC.SIM,'ForcePos',ObsC.objXY,'OnlyForce',true,'ForceCatCol',{'X','Y'},'SearchCR',false,'AperBackErrFun',@nanstd,...
                'AperBackFun',@nanmedian,'Verbose',false,'WinPosFromForce',InPar.WinPosFromForce);
            
            ObsC.current_forced_astcat =S.sim2astcat;
            if isempty(ObsC.forced_astcat)
                ObsC.forced_astcat =ObsC.current_forced_astcat ;
            else
                ObsC.forced_astcat.Cat = [ObsC.forced_astcat.Cat;ObsC.current_forced_astcat .Cat];
            end
        end
        
    end
    
    
    methods
        % scripts
        function obs_run_pipe(ObsC,varargin)
            
            InPar =inputParser;
            addOptional(InPar ,'SavePath','');
            parse(InPar,varargin{:});
            InPar = InPar.Results;
            
            ObsC.SavePath = InPar.SavePath;
            mkdir(ObsC.SavePath);
            ObsC.log_file = [ObsC.SavePath 'log.txt'];
            % run the pipeline for forced photmetery
            ObsC.load_image;
            log_fileID = fopen(ObsC.log_file,'a');
            try
                ObsC.run_mextractor('Thresh',ObsC.full_img_thresh);
            catch
                fprintf(log_fileID,'Failed in full frame mextractor')
                return
            end
            ObsC.solve_astrometry;
            ObsC.object_xy_pos;
            
            disp('Saving the full Observation Object')
            ObsC.save_full
            
            for Iimage  = 1:numel(ObsC.DirObj)
                ObsC.current_image = Iimage;
                disp(['Current Image -  ' num2str(ObsC.current_image) ' out of ' num2str(numel(ObsC.DirObj))]);
                ObsC.load_image('ImageNum',Iimage);
                ObsC.trimImage
                try
                    ObsC.run_mextractor('Thresh',ObsC.cut_img_thresh);
                    ObsC.Failed(Iimage)=0;
                catch
                    fprintf(log_fileID,['Directory - ' ObsC.ImagesPath{Iimage} ' - first mextractor failed \n']);
                    ObsC.Failed(Iimage)=1;
                end
                
                ObsC.solve_astrometry('RA',ObsC.objRA,'DEC',ObsC.objDec,'SearchRangeY',[-100,100],'SearchRangeX',[-100,100]);
                ObsC.object_xy_pos;
                ObsC.Gaia_cm
                ObsC.current_astcat =ObsC.SIM.sim2astcat;
                ObsC.forced_photometry
                ObsC.current_PSF_zeros =ObsC.PSF_sum_zero(ObsC);
                ObsC.PSF_zeros(Iimage) = ObsC.current_PSF_zeros;
                ObsC.save_current
                
                
                
                
                
                
                
                
            end
            ObsC.save_full
            
        end
        
        
        
        function extract_lightcurve(ObsC,varargin)
            %Extracting the object calibrated light curve from a directory.
            %The function populated the forced_astcat by the forced
            %photmetry of each image, calculate the zp using Gaia Bp and
            %calibrate the MAG_PSF.
            InPar =inputParser;
            addOptional(InPar ,'StrInFile','result');
            parse(InPar,varargin{:});
            InPar = InPar.Results;
            ObsC.saved_dir= dir([ObsC.SavePath '*' InPar.StrInFile '*']);
            ObsC.forced_astcat=[];
            for i =  1:numel(ObsC.saved_dir)
                disp(['File number  ' num2str(i) '  out of ---' num2str(numel(ObsC.saved_dir))]);
                ObsC.upload_data('ImageNum',i);
                ObsC.ZeroPoint(i)=ObsC.fit_zp;
                jd=cell2mat(getkey(ObsC.loaded_data.current_forced_astcat,'JD'));
                ObsC.loaded_data.current_forced_astcat=col_insert(ObsC.loaded_data.current_forced_astcat,jd,2,'JD');
                
                if isempty(ObsC.forced_astcat)
                    ObsC.forced_astcat=ObsC.loaded_data.current_forced_astcat;
                    
                else
                    ObsC.forced_astcat.Cat=[ObsC.forced_astcat.Cat;ObsC.loaded_data.current_forced_astcat.Cat];
                end
            end
            
        end
        
        
        
    end
    
    
    methods (Static)
        
        
        
        function nzero = PSF_sum_zero(ObsC)
            
            nzero=sum(sum(ObsC.SIM.PSF,1)==0);
            
        end
        
        
    end
    
    
    
    
    
end