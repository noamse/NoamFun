classdef ObjML< handle
    properties (SetAccess = public)
        Folder
        SIM
        ImagesPath
        ImagesType='fits';
        im_h5opt = '/images';
        SavePath
        DirObj
        img_thresh=5;
        astrometry_Res
        WCS
        
        objra = convert.hms2angle('18:06:09.11','rad');
        objdec = convert.dms2angle('-26:04:41.20','rad');
        objXY = [131,593]
        obj_align = [131,593]
        matched
        match_res
        match_summary
        fit_mat
        
        forced_astcat
        current_forced_astcat
        
        
        design_mat_fun
        imagesize = [1212,1214] % image size (pixels)
        log_file;
        current_image;
        astcat
        saved_files
        
        Xfit=[];
        Yfit=[];
        match_xy_centered = false;
    end
    
    
    methods % Constructor
        
        function ObjC = ObjML(Folder)
            ObjC.Folder = Folder;
            ObjC.DirObj = dir([ObjC.Folder '*.' ObjC.ImagesType]);
            ObjC.ImagesPath = strcat(ObjC.Folder,{ObjC.DirObj.name});
        end
        
    end
    
    methods % Get/Set methods
        
        function set.SavePath(ObsC,val)
            if isempty(val)
                ObsC.SavePath = '/home/noamse/astro/KMT_ML/data/results/astcat/';
            else
                ObsC.SavePath =val;
            end
            
            
        end
        
        
        
    end
    
    methods % functions
        
        
        function update_cord(objML)
            % Update coordinates - can be used to convert deg to rad
            if ~isempty(objML.SIM)
                objML.SIM = update_coordinates(objML.SIM);
            end
        end
        
        
        function ObsC =load_image(ObsC,varargin)
            % Load image from directory
            InPar =inputParser;
            addOptional(InPar ,'ImageNum',1);
            parse(InPar,varargin{:});
            InPar = InPar.Results;
            
            
            
            ObsC.SIM=ut.read2sim(ObsC.ImagesPath{InPar.ImageNum});
            ObsC.current_image = InPar.ImageNum;
            
            
            
            
            
        end
        
        
        
        function run_mextractor(objML,varargin)
            % Load image from directory
            InPar =inputParser;
            addOptional(InPar ,'Thresh',objML.img_thresh);
            %addOptional(InPar ,'RunForced',true);
            parse(InPar,varargin{:});
            InPar = InPar.Results;
            
            if isempty(objML.SIM)
                disp('No sim Obecjt in Observation Class')
            end
            objML.SIM= mextractor(objML.SIM,'AperBackErrFun',@nanstd,'AperBackFun',@nanmedian...
                ,'Thresh',InPar.Thresh,'FilterFindThresh',InPar.Thresh);
            
            
            
        end
        
        function populate_astcat(objML)
            objML.astcat = AstCat.sim2astcat(objML.SIM);
        end
        
        
        function save_astcat(objML,varargin)
            InPar =inputParser;
            addOptional(InPar ,'Field2Save',{'astcat','current_image','DirObj'});
            
            parse(InPar,varargin{:});
            InPar = InPar.Results;
            st=[];
            for i = 1:numel(InPar.Field2Save)
                
                st.(InPar.Field2Save{i}) = objML.(InPar.Field2Save{i});
            end
            saved_filename = [objML.SavePath 'result_image_' num2str(objML.current_image) '.mat'];
            save(saved_filename,'st')
            objML.saved_files{objML.current_image} = saved_filename;
            
        end
        
        
        
        function save_full(objML)
            
            save([objML.SavePath 'objML.mat'],'objML','-v7.3')
        end
        
        
        
    end
    
    
    
    methods
        
        
        function extract_catalog(objML,varargin)
            %
            InPar =inputParser;
            addOptional(InPar ,'SavePath','');
            parse(InPar,varargin{:});
            InPar = InPar.Results;
            objML.SavePath = InPar.SavePath;
            mkdir(objML.SavePath);
            objML.log_file = [objML.SavePath 'log.txt'];
            for Iim = 1:numel(objML.DirObj)
                disp('----');
                disp('----');
                disp(['Image -' num2str(Iim) '  out of -' num2str(numel(objML.DirObj))]);
                disp('----');
                disp('----');
                objML.load_image('ImageNum',Iim);
                objML.run_mextractor;
                objML.update_cord;
                objML.populate_astcat
                objML.save_astcat;
                
                
                
            end
            objML.save_full
            
        end
        
        
        function load_astcats(objML)
            for Iim = 1:numel(objML.saved_files)
                a = load(objML.saved_files{Iim});
                objML.astcat(Iim) = a.st.astcat;
                %objML.astcat(Iim) =
                
            end
            
            
        end
        
        
        function match(objML,varargin)
            InPar =inputParser;
            addOptional(InPar ,'Colls2return',{'XWIN_IMAGE','YWIN_IMAGE','MAG_PSF','ALPHAWIN_J2000','DELTAWIN_J2000'...
                ,'SN_PSF','PSF_CHI2','MAGERR_PSF','NEAREST_SRCDIST','FLUX_PSF'});
            addOptional(InPar ,'SearchRad',0.9);
            addOptional(InPar ,'RefImgNum',1);
            parse(InPar,varargin{:});
            InPar = InPar.Results;
            
            %Colls2return={'XWIN_IMAGE','YWIN_IMAGE','MAG_PSF','ALPHAWIN_J2000','DELTAWIN_J2000','SN_PSF','PSF_CHI2','MAGERR_PSF','NEAREST_SRCDIST','FLUX_APER_3'};
            
            [AstOut,~]=match(objML.astcat,objML.astcat(InPar.RefImgNum),'SkipWCS',true,'SearchRad',InPar.SearchRad);
            [res,summary] = astcat2matched_array(AstOut,InPar.Colls2return);
            objML.match_summary=summary;
            objML.match_res=res;
            
            
        end
        
        function flag_match(objML,varargin)
            InPar =inputParser;
            addOptional(InPar ,'AppearFactor',0.8);
            addOptional(InPar ,'SNthresh',50);
            parse(InPar,varargin{:});
            InPar = InPar.Results;
            
            flag=sum(~isnan(objML.match_res.XWIN_IMAGE'))>InPar.AppearFactor*numel(objML.astcat);
            flagSN = nanmean(objML.match_res.SN_PSF')>InPar.SNthresh;
            objML.match_res=flag_struct_field(objML.match_res,flag&flagSN);
            
            
        end
        
        
        
        function xy_for_fit(objML,varargin)
            InPar =inputParser;
            addOptional(InPar ,'XName','XWIN_IMAGE');
            addOptional(InPar ,'YName','YWIN_IMAGE');
            addOptional(InPar ,'Direction',true);
            parse(InPar,varargin{:});
            InPar = InPar.Results;
            
            objML.Xfit = objML.match_res.(InPar.XName)- objML.imagesize(1)/2;
            objML.Yfit = objML.match_res.(InPar.YName)- objML.imagesize(2)/2;
            
        end
        
        function fit_affine(objML,varargin)
            % fit affine transformation between the first image and the
            % other images of the FOV. The result will be inserted to
            % objML.affine_trans.
            InPar =inputParser;
            addOptional(InPar ,'XName','XWIN_IMAGE');
            addOptional(InPar ,'YName','YWIN_IMAGE');
            addOptional(InPar ,'MagName','MAG_PSF');
            addOptional(InPar ,'RefImgNum',1);
            parse(InPar,varargin{:});
            InPar = InPar.Results;
            
            X=  objML.Xfit;
            Y=  objML.Yfit;
            Xref = X(:,InPar.RefImgNum);
            Yref = Y(:,InPar.RefImgNum);
            FlagRef = ~isnan(Yref)&~isnan(Xref);
            H = @(x,y) [ones(size(x)),x,y];
            
            for i  = 1:numel(X(1,:))
                FlagCurrent = ~isnan(X(:,i))&~isnan(Y(:,i));
                D= sqrt((X(:,i)-Xref).^2 + (Y(:,i)-Yref).^2);
                
                flag = FlagRef&FlagCurrent;
                x=Xref(flag);
                y=Yref(flag);
                sig_clip = isoutlier(D(flag));
                x_temp = X(flag,i);
                y_temp = Y(flag,i);
                objML.fit_mat{i}= H(x_temp(~sig_clip),y_temp(~sig_clip))\[x(~sig_clip),y(~sig_clip)];
            end
            
            objML.design_mat_fun = H;
            
        end
        
        
        function fit_poly(objML,varargin)
            % fit affine transformation between the first image and the
            % other images of the FOV. The result will be inserted to
            % objML.affine_trans.
            InPar =inputParser;
            addOptional(InPar ,'XName','XWIN_IMAGE');
            addOptional(InPar ,'YName','YWIN_IMAGE');
            addOptional(InPar ,'MagName','MAG_PSF');
            addOptional(InPar ,'degree', 4);
            addOptional(InPar ,'useCov', false);
            addOptional(InPar ,'CovPower',-2);
            addOptional(InPar ,'RefImgNum',1);
            
            parse(InPar,varargin{:});
            InPar = InPar.Results;
            
            X=  objML.Xfit;
            Y=  objML.Yfit;
            Xref = X(:,InPar.RefImgNum);
            Yref = Y(:,InPar.RefImgNum);
            FlagRef = ~isnan(Yref)&~isnan(Xref);
            switch InPar.degree
                case 4
                    H = @(x,y) [ones(size(x)),x,y,x.^2,y.^2,x.*y,x.^3,y.^3,x.*y.^2,y.*x.^2,x.^4,y.^4,x.^3.*y,x.^2.*y.^2,x.*y.^3];
                case 3
                    H = @(x,y) [ones(size(x)),x,y,x.^2,y.^2,x.*y,x.^3,y.^3,x.*y.^2,y.*x.^2];
                case 2
                    H = @(x,y) [ones(size(x)),x,y,x.^2,y.^2,x.*y];
            end
            for i  = 1:numel(X(1,:))
                FlagCurrent = ~isnan(X(:,i))&~isnan(Y(:,i));
                D= sqrt((X(:,i)-Xref).^2 + (Y(:,i)-Yref).^2);
                
                flag = FlagRef&FlagCurrent;
                x=Xref(flag);
                y=Yref(flag);
                sig_clip = isoutlier(D(flag));
                x_temp = X(flag,i);
                y_temp = Y(flag,i);
                if InPar.useCov
                    %D = sqrt((x_temp(~sig_clip)-x_temp(~sig_clip)').^2 + (y_temp(~sig_clip)-y_temp(~sig_clip)').^2);
                    D =zeros(size(x_temp(~sig_clip)-x_temp(~sig_clip)'));
                    PSF_err = nanmean(objML.match_res.MAGERR_PSF,2);
                    PSF_err = PSF_err(flag);
                    PSF_err =PSF_err(~sig_clip);
                    D(find(eye(size(D)))) = PSF_err.^2;
                    
                    %objML.fit_mat{i}= lscov(H(x_temp(~sig_clip),y_temp(~sig_clip)),[x(~sig_clip),y(~sig_clip)],(D.^(InPar.CovPower)));
                    objML.fit_mat{i}= lscov(H(x_temp(~sig_clip),y_temp(~sig_clip)),[x(~sig_clip),y(~sig_clip)],D);
                else
                    objML.fit_mat{i}= H(x_temp(~sig_clip),y_temp(~sig_clip))\[x(~sig_clip),y(~sig_clip)];
                end
            end
            
            
            objML.design_mat_fun = H;
        end
        
        
        
        function Alg = aligned_cat(objML)
            % apply the affine transformation to the matched catalog
            
            
            Alg=[];
            Alg.X=zeros(size(objML.Xfit));
            Alg.Y=zeros(size(objML.Yfit));
            
            for i=1:numel(objML.DirObj)
                
                Xim = objML.Xfit(:,i);
                Yim = objML.Yfit(:,i);
                %H= [ones(size(Yim)),Xim,Yim];
                XY = objML.design_mat_fun(Xim,Yim)*objML.fit_mat{i};
                
                Alg.X(:,i) = XY(:,1);
                Alg.Y(:,i) = XY(:,2);
                
                %
            end
            
        end
        
        
        
        
        function forced_photometry(objML,varargin)
            InPar =inputParser;
            addOptional(InPar ,'WinPosFromForce',false);
            addOptional(InPar ,'XY',objML.objXY);
            addOptional(InPar ,'Thresh',objML.img_thresh);
            parse(InPar,varargin{:});
            InPar = InPar.Results;
            %ObsC = object_xy_pos(ObsC);
            
            S= mextractor(objML.SIM,'ForcePos',InPar.XY,'OnlyForce',true,'ForceCatCol',{'X','Y'},'SearchCR',false,'AperBackErrFun',@nanstd,...
                'AperBackFun',@nanmedian,'Verbose',false,'WinPosFromForce',InPar.WinPosFromForce...
                ,'Thresh',InPar.Thresh,'FilterFindThresh',InPar.Thresh);
            jd = cell2mat(getkey(S,'MIDJD'));
            S=col_insert(S,jd,2,'JD');
            objML.current_forced_astcat =S.sim2astcat;
            if isempty(objML.forced_astcat)
                objML.forced_astcat =objML.current_forced_astcat ;
            else
                objML.forced_astcat.Cat = [objML.forced_astcat.Cat;objML.current_forced_astcat .Cat];
            end
        end
        
        
        
        function event_aligned_xy(objML)
            objX = objML.objXY(1) - objML.imagesize(1)/2;
            objY = objML.objXY(2) - objML.imagesize(2)/2;
            
            for i=1:numel(objML.ImagesPath)
                objML.obj_align(i,:)=objML.design_mat_fun(objX,objY)*objML.fit_mat{i};
                
            end
            objML.obj_align=objML.obj_align + objML.imagesize/2;
        end
        
        
        
        
        function extract_event_astcat(objML)
            objML.forced_astcat=[];
            for i =1:numel(objML.obj_align(:,1))
                disp('--------------')
                disp('--------------')
                disp('--------------')
                disp(['Image number        ' num2str(i)])
                disp('--------------')
                disp('--------------')
                disp('--------------')
                objML.load_image('ImageNum',i);
                objML.forced_photometry('XY',objML.obj_align(i,:),'Thresh',300);
                
                
                
                
                
                
            end
            
            
        end
    end
    
    
    
    
    
    methods (Static)
        
        
        function XY_alg = align_pos(XY,fit_mat,design_mat)
            % Apply the transformation matric on the pixel XY in each
            % epoch. The XY is expected to be centered (i.e., X-CCD/2)
            XY_alg=zeros(size(XY));
            for i =1:numel(fit_mat)
                XY_alg(i,:) = design_mat(XY(i,1),XY(i,2))*fit_mat{i};
            end
            
        end
        
        
        
        function [Res,IndBest,H2] = match_shift_rot(Cat,Ref,varargin)
            InPar =inputParser;
            addOptional(InPar ,'AppearFactor',0.8);
            addOptional(InPar ,'Rotation',0);
            addOptional(InPar ,'SearchRangeX',[-100,100]);
            addOptional(InPar ,'SearchRangeY',[-100,100]);
            addOptional(InPar ,'SearchStep',0.2);
            parse(InPar,varargin{:});
            InPar = InPar.Results;
            
            [Res,IndBest,H2]=ImUtil.pattern.match_pattern_shift(Cat,Ref...
                ,'ColXc',2,'ColYc',3,'ColXr',2,'ColYr',3,'Radius',1,...
                'SearchStepX',InPar.SearchStep,'SearchStepY',InPar.SearchStep,'SearchRangeY',InPar.SearchRangeY,'SearchRangeX',InPar.SearchRangeX);
        end
        
        function [flux,zp] = zp_calibration(objML)
            flux  = objML.match_res.FLUX_PSF;
            index = find(sum(isnan(flux'))==0);
            zp=zeros(numel(objML.DirObj),1);
            for i= 1:numel(objML.DirObj)
                zp(i) =nansum(flux(index,i));
                flux(:,i) = flux(:,i)./zp(i);
            end
            
        end
        
        
        
        function [res] = fit_epochs_pairs(objML,Cat1_Ind,Cat2_Ind,varargin)
            % return the coordinates fit between a pair of epochs
            
            
            InPar =inputParser;
            addOptional(InPar ,'Colls2return',{'XWIN_IMAGE','YWIN_IMAGE','MAG_PSF','ALPHAWIN_J2000','DELTAWIN_J2000'...
                ,'SN_PSF','PSF_CHI2','MAGERR_PSF','NEAREST_SRCDIST','FLUX_PSF'});
            addOptional(InPar ,'SearchRad',1.5);
            addOptional(InPar ,'degree',4);
            addOptional(InPar ,'extract_cat',false);
            addOptional(InPar ,'Cat1',[]);
            addOptional(InPar ,'Cat2',[]);
            parse(InPar,varargin{:});
            InPar = InPar.Results;
            
            if InPar.extract_cat
                Cat1= InPar.Cat1;
                Cat2= InPar.Cat2;
            else
                Cat1= objML.astcat(Cat1_Ind);
                Cat2= objML.astcat(Cat2_Ind);
            end
                
            
            [AstOut,~]=match([Cat1,Cat2],Cat1,'SkipWCS',true,'SearchRad',InPar.SearchRad);
            [res,summary] = astcat2matched_array(AstOut,InPar.Colls2return);
            
            
            flag = ~isnan(res.XWIN_IMAGE) &~isnan(res.YWIN_IMAGE);
            flag = flag(:,1)&flag(:,2);
            X = res.XWIN_IMAGE(flag,:)-objML.imagesize(1)/2;
            
            Y = res.YWIN_IMAGE(flag,:)-objML.imagesize(2)/2;
            res.flag=flag;
            
            
            switch InPar.degree
                case 4
                    H = @(x,y) [ones(size(x)),x,y,x.^2,y.^2,x.*y,x.^3,y.^3,x.*y.^2,y.*x.^2,x.^4,y.^4,x.^3.*y,x.^2.*y.^2,x.*y.^3];
                case 3
                    H = @(x,y) [ones(size(x)),x,y,x.^2,y.^2,x.*y,x.^3,y.^3,x.*y.^2,y.*x.^2];
                case 2
                    H = @(x,y) [ones(size(x)),x,y,x.^2,y.^2,x.*y];
            end
            
            
            res.fit_mat= H(X(:,1),Y(:,1))\[X(:,2),Y(:,2)];
            
            res.cat_pos = H(X(:,1),Y(:,1))*res.fit_mat;
            res.ref_pos = [X(:,2),Y(:,2)];
            res.dX = res.cat_pos(:,1) - res.ref_pos(:,1);
            res.dY = res.cat_pos(:,2) - res.ref_pos(:,2);
            res.Xbar = mean(X + objML.imagesize(1)/2,2);
            res.Ybar = mean(Y + objML.imagesize(2)/2,2);
            
            res.sig3_clip = ~isoutlier(sqrt(res.dX.^2 + res.dY.^2),'ThresholdFactor',1);
            
            res.fit_mat_clip= H(X(res.sig3_clip,1),Y(res.sig3_clip,1))\[X(res.sig3_clip,2),Y(res.sig3_clip,2)];
            
            res.cat_pos_clip= H(X(:,1),Y(:,1))*res.fit_mat_clip;
            
            res.dX_clip = res.cat_pos_clip(:,1) - res.ref_pos(:,1);
            res.dY_clip = res.cat_pos_clip(:,2) - res.ref_pos(:,2);
            
            
        end
        
        
    end
    
end


