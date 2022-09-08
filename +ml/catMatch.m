classdef catMatch< handle
    
    % Astronomical image from a certain field matching.
    % This class used to solve relative astrometry of observed astronomical
    % field.
    
    
    
    
    % The class will get a AstroCatalog containing the extracted sources
    % (e.g., imProc.sources.findMeasureSources), match the catalogs and fit for
    % relative astrometry.
    
    
    
    properties (Access = public)
        AstCat = AstroCatalog;
        AstWCS = AstroWCS;
        MatchMat =[];
        RefCat=[];
        RefCat_pm=[];
        pixscale= 0.4; % arcsec/pix
        NormScale =400;
        pix2mas
        pixelshift = [400,400];
        isPixScaled = 0;
        % properties for MatchCat
        MatchRadius = 1; %
        %         RetrunCols = {'X','Y','MAG_CONV_'...
        %             ,'SN_1','FLUX_CONV_1','MAGERR_CONV_1'...
        %            };%,'MAGERR_PSF'};
        %RetrunCols = {'X','Y','MAG_PSF' ,'SN_3' ,'FLUX_PSF','MAGERR_APER_3'...
        RetrunCols = {'X','Y','MAG_PSF' ,'FLUX_PSF'...
            ,'fwhm','secz','pa','PSF_CHI2DOF'};%,'MAGERR_PSF'};
        Match_Summary;
        Match_N_Ep;
        MS = [];
        MagColName = 'MAG_PSF';
        SNColName = 'SN_3';
        FluxColName = 'FLUX_PSF';
        MagErrColName = 'MAGERR_APER_3';
        MS_fields = {'X','Y','MAG_PSF' ,'SN_3' ,'FLUX_PSF','MAGERR_APER_3' }
        ApearenceFactor=0.75;
        unMatchFlag=[];
        % propertied for fit_pattern
        
        PatternMat = {};
        Pattern_failed=[];
        
        % propertied for fit_affine
        AffineMat = {};
        AffineCols = {'X','Y',[]};
        AffineFuns = {1,1,[]};
        
        % properties for fit_distortion
        DistortionCols = {[],'X','Y','X','Y'};
        DistortionFuns = {[],1,1,2,2};
        DistortionOrder=4;
        Ax=[];
        Ay=[];
        mag_range=[10,13];
        N_dist_outliers=[];
        rms_dist_fit=[];
        outliers_in_dist_fit=[];
        % zero point fiting
        zp=[]
        pm_err_prctl=50;
        
        % proper motion
        pm_x=[]
        pm_y=[]
        pm_x_err=[]
        pm_y_err=[]
        RefJD = celestial.time.date2jd([2018,1,1]);
        plx_par=[];
        plx_par_err=[];
    end
    
    methods % Constructor
        
        function CM = catMatch(AstCat)
            
            CM.AstCat= AstCat;
            CM.MS=MatchedSources;
            jd = [AstCat.JD];
            CM.MS.JD = jd(:);
        end
        
        
        
    end
    
    methods % setters and getters
        
        
        function Ref = get.RefCat(CM)
            if isempty(CM.RefCat)
                Ref = CM.AstCat(20);
            else
                Ref=CM.RefCat;
            end
        end
        
        
        function scale= get.pix2mas(CM)
            
            scale = CM.pixscale *1000 ;
        end
    end
    
    
    methods %Data collection, match and fit pattern
        
        
        function matchCat(CM)

            
            Matched = imProc.match.matchedReturnCat(CM.RefCat,CM.AstCat,'CooType','pix','Radius',CM.MatchRadius);
            
            CM.MS.addMatrix(Matched,CM.RetrunCols);

            
        end
        
        function clear_unmatched(CM)
            % clear unmatched sources using an appearence criteria
            
            CM.unMatchFlag =sum(~isnan(CM.MS.Data.X))>numel(CM.MS.JD)*CM.ApearenceFactor;
            CM.MS.Data= flag_struct_field(CM.MS.Data,CM.unMatchFlag ,'FlagByCol',true);
            
            
        end
        function fit_pattern(CM)
            % Fit pattren of the AstroCatalog array with respect to the
            % reference image, This procedure is rough with steps of 0.1
            % pixels.
            
            for IndCat = 1:numel(CM.AstCat)
                
                try
                    [II] = imProc.trans.fitPattern(CM.RefCat,CM.AstCat(IndCat),'StepX',0.5,'StepY',0.5,...
                        'RangeX',[-100.5,100.5],'RangeY',[-100.25,100.25],'SearchRadius',2,'HistRotEdges',(-90:0.2:90),...
                        'MaxMethod','max1');
                    [NewX,NewY]=imUtil.cat.affine2d_transformation(CM.AstCat(IndCat).Catalog,II.Sol.AffineTran{1},'+'...
                   ,'ColX',CM.AstCat(IndCat).colname2ind('X'),'ColY',CM.AstCat(IndCat).colname2ind('Y'));
                    
                    CM.PatternMat{IndCat} =II.Sol.AffineTran;
                catch
                    CM.Pattern_failed= [CM.Pattern_failed,IndCat];
                    CM.PatternMat{IndCat}= {};
                end
            end
            
            
        end
        
        function CM = clear_pattern_failed(CM)
            
            CM.AstCat(CM.Pattern_failed)=[];
            CM.PatternMat(CM.Pattern_failed)=[];
            if ~isempty(CM.MS.JD)
                CM.MS.JD(CM.Pattern_failed)=[];
            end
        end
        
        function CM = apply_shift_scale(CM)
            % Scale and shift the pixel coordinates to avoid nomerical
            % instabilities in sufficticated fits. dir is the shift_scale
            % direction.
            if CM.isPixScaled  ==0
                CM.MS.Data.X = (CM.MS.Data.X-CM.pixelshift(1))/CM.NormScale;
                CM.MS.Data.Y = (CM.MS.Data.Y-CM.pixelshift(2))/CM.NormScale;
                
            end
            CM.isPixScaled  =1;
            
        end
        
        function CM = revert_shift_scale(CM)
            
            if CM.isPixScaled==1
                CM.MS.Data.X = CM.MS.Data.X*CM.NormScale + CM.pixelshift(1);
                CM.MS.Data.Y = CM.MS.Data.Y*CM.NormScale + CM.pixelshift(2);
                CM.isPixScaled=0;
            end
        end
        
        function CM = apply_pattern(CM)
            % Apply the pattern shift
            for i=1:numel(CM.AstCat)
                %Xvec = [CM.MS.Data.X(i,:);CM.MS.Data.Y(i,:);ones(size(CM.MS.Data.X(i,:)))];
                %Xtag = CM.PatternMat{i}{1} * Xvec ;
                %CM.MS.Data.X(i,:) = Xtag(1,:);
                %CM.MS.Data.Y(i,:) = Xtag(2,:);
                %Xcat = CM.AstCat(i).getCol({'X','Y'});
                %Xvec  = [Xcat';ones(size(Xcat(:,1)'))];
                [NewX,NewY]=imUtil.cat.affine2d_transformation(CM.AstCat(i).Catalog,CM.PatternMat{i}{1},'+'...
                    ,'ColX',CM.AstCat(i).colname2ind('X'),'ColY',CM.AstCat(i).colname2ind('Y'));
                
                CM.AstCat(i).Catalog(:,CM.AstCat(i).colname2ind('X')) = NewX;
                CM.AstCat(i).Catalog(:,CM.AstCat(i).colname2ind('Y')) = NewY;
            end
            
        end
        
        
        
        
        
        
        
        
        
    end
    
    
    methods % Fit transformations
        
        function CM= fit_affine(CM,Args)
            
            arguments 
               CM;
               Args.GlobalRef=false;
               Args.OnlyMagRange=false;
            end
            
            X = CM.MS.Data.X';
            Y = CM.MS.Data.Y';
            %MAG_PSF=CM.MS.Data.MAG_PSF';
            %PSF_CHI2DOF = CM.MS.Data.PSF_CHI2DOF';
            %FLUX_PSF = CM.MS.Data.FLUX_PSF';
            
            %SN = CM.MS.Data.(CM.SNColName);
            RefX = X(:,1);
            RefY = Y(:,1);
            for i =1:numel(CM.AstCat)
                if Args.GlobalRef
                    RefCat_ast = CM.create_reference(CM.MS.JD(i));
                    RefX=RefCat_ast.getCol('X');
                    RefY=RefCat_ast.getCol('Y');
                end
                %H = [X(i,:)',Y(i,:)',ones(size(RefX'))];
                H = CM.designMatrix(i,CM.AffineCols , CM.AffineFuns);
                
                MAG_PSF=CM.MS.Data.MAG_PSF(i,:)';
                PSF_CHI2DOF = CM.MS.Data.PSF_CHI2DOF(i,:)';
                FLUX_PSF = CM.MS.Data.FLUX_PSF(i,:)';
                
                
                if sum(~isnan(FLUX_PSF))>30
                    
                    [xmid, ymid, ~,~] =  ut.calc_bin_fun(MAG_PSF,PSF_CHI2DOF./FLUX_PSF.^2,'Nbins',10,'fun',@nanmedian);
                    interp_w = interp1(xmid,ymid,MAG_PSF);
                    w = (PSF_CHI2DOF./FLUX_PSF.^2).^(-1);
                end
                
                
                Flag = ~isnan(X(:,i))&~isnan(Y(:,i)) &~isnan(RefX)...
                    &~isnan(RefY) & ~isnan(w);
                
                
                
                if Args.OnlyMagRange
                    
                    Flag = Flag & CM.IsInMagRange(RefCat_ast.getCol(CM.MagColName));
                    
                end
                if i==158
                    a=3;
                end
                Ht = H(Flag,:);
                Xt = RefX(Flag);
                Yt = RefY(Flag);
                wt = w(Flag);
                ax = lscov(Ht,Xt,wt);
                ay = lscov(Ht,Yt,wt);
                
                isoutx = isoutlier(Ht*ax-Xt,'percentile',[20,80]);
                isouty= isoutlier(Ht*ay-Yt,'percentile',[20,80]);
                
                isout= isoutx|isouty;
                %isout= false(size(isouty));
                ax = lscov(Ht(~isout,:),Xt(~isout),wt(~isout));
                ay = lscov(Ht(~isout,:),Yt(~isout),wt(~isout));
                CM.AffineMat{i} = [ax';ay';0,0,1];
                
            end
            % Fit affine transformations
            
        end
        
        
        function CM = apply_affine(CM)
            % Apply the pattern shift
            for i=1:numel(CM.MS.JD)
                Xvec = [CM.MS.Data.X(i,:);CM.MS.Data.Y(i,:);ones(size(CM.MS.Data.X(i,:)))];
                Xtag = CM.AffineMat{i} * Xvec ;
                CM.MS.Data.X(i,:) = Xtag(1,:);
                CM.MS.Data.Y(i,:) = Xtag(2,:);
            end
            
        end
        
        
        function [H] = designMatrix(CM,EpochInd,ColNames, FunCell)%, ColNameY, FunY, ColNameErrY, FunErrY)
            % generate design matrix. Based on MatchedSources, but modified
            % to inter epoch fit
            
            arguments
                CM
                EpochInd
                ColNames
                FunCell
                %ColNameY char
                %FunY             = @(x) ones(size(x));
                %ColNameErrY char = [];
                %FunErrY          = @(x) ones(size(x));
            end
            Obj=CM.MS;
            if ~iscell(FunCell)
                FunCell = {FunCell};
            end
            if ischar(ColNames)
                ColNames = {ColNames};
            end
            
            Nfun = numel(FunCell);
            if Nfun~=numel(ColNames)
                error('FunCell and ColNames must contain the same number of elements');
            end
            
            Npt = Obj.Nsrc;
            % design matrix
            H   = nan(Npt, Nfun);
            for Ifun=1:1:Nfun
                if isa(FunCell{Ifun}, 'function_handle')
                    H(:,Ifun) = FunCell{Ifun}( Obj.Data.(ColNames{Ifun})(EpochInd,:) );
                else
                    % functional may be [] -> ones, or number -> power
                    if isempty(FunCell{Ifun})
                        % ones
                        H(:,Ifun) = ones(Npt,1);
                    else
                        % power
                        H(:,Ifun) = Obj.Data.(ColNames{Ifun})(EpochInd,:).^FunCell{Ifun};
                    end
                end
            end
            
            
            
            
        end
        
        function CM = fit_distortion(CM,Flux,Args)
            
            arguments
                CM
                Flux = nanmean(CM.MS.Data.(CM.FluxColName))';
                Args.CutMag  = false;
                Args.flag_pm_err=false;
            end
            %if all(Flux==1)
            %    Flux = ones(size(nanmean(CM.MS.Data.(CM.FluxColName))'));
            %end
            % Fit for distortion using polynomials.
            CM.Ax=[];
            CM.Ay=[];
            
            %RefX = CM.MS.Data.X(1,:)';
            %RefY = CM.MS.Data.Y(1,:)';
            %[RefX,RefY]=CM.refXY;
            RefCat_fl = CM.create_reference(CM.MS.JD(1),'flag_pm_err',Args.flag_pm_err);
            Flux = RefCat_fl.getCol('FLUX_PSF');
            CHI2DOF= RefCat_fl.getCol('PSF_CHI2DOF');
            CM.outliers_in_dist_fit=false(size(CM.MS.Data.X));
            
            for i = 1:numel(CM.MS.JD)
                %X = CM.MS.Data.('X')(i,:)';
                %Y = CM.MS.Data.('Y')(i,:)';
                
                RefCat_ast = CM.create_reference(CM.MS.JD(i),'flag_pm_err',Args.flag_pm_err);
                RefX=(RefCat_ast.getCol('X')-CM.pixelshift(1))/CM.NormScale;
                RefY=(RefCat_ast.getCol('Y')-CM.pixelshift(2))/CM.NormScale;
                H = CM.distortion_design_matrix(i,CM.DistortionOrder,'flag_pm_err',Args.flag_pm_err);
                
                if Args.CutMag
                    Flag = ~any(isnan(H),2) &~isnan(RefX)...
                        &~isnan(RefY) ...
                        & CM.IsInMagRange(RefCat_ast.getCol('MAG_PSF'));
                else
                    Flag = ~any(isnan(H),2) &~isnan(RefX)...
                        &~isnan(RefY);
                end
                CM.outliers_in_dist_fit(i,~Flag)=false;
                
                H= H(Flag,:);
                XrefT = RefX(Flag);
                YrefT = RefY(Flag);
                FluxT = Flux(Flag);
                CHI2DOFT = CHI2DOF(Flag);
                w= FluxT./CHI2DOFT;
                ax = lscov(H,XrefT ,w);
                ay = lscov(H,YrefT ,w);
                
                isout= isoutlier(H*ax-CM.MS.Data.X(i,Flag)','percentile',[20,80]) | isoutlier(H*ay-CM.MS.Data.Y(i,Flag)','percentile',[20,80]);
                CM.N_dist_outliers(i)=sum(isout);
                CM.outliers_in_dist_fit(i,Flag)=isout';
                CM.Ax(:,i) = lscov(H(~isout,:),XrefT(~isout) ,w(~isout));
                CM.Ay(:,i) = lscov(H(~isout,:),YrefT(~isout) ,w(~isout));
                Xtest= CM.MS.Data.X(i,Flag)';
                CM.rms_dist_fit(i)=rms(H(~isout,:)*CM.Ax(:,i)-Xtest(~isout));
                
            end
            
            
            
            
        end
        
        
        
        
        function [X,Y]=refXY(CM)
            % generate Reference image for the affine-fitted catalogs
            
            indexes = 100:120;
            X =  nanmean(CM.MS.Data.X(indexes,: )',2);
            Y =  nanmean(CM.MS.Data.Y(indexes,: )',2);
            
            
        end
        
        
        
        
        
        function apply_distortion(CM,Args)
            arguments
                CM;
                Args.flag_pm_err = false;
            end
            for i=1:numel(CM.MS.JD)
                %Xvec = [CM.MS.Data.X(i,:);CM.MS.Data.Y(i,:);ones(size(CM.MS.Data.X(i,:)))];
                H = CM.distortion_design_matrix(i,CM.DistortionOrder,'flag_pm_err',Args.flag_pm_err  );
                Xvec  = H*CM.Ax(:,i);
                Yvec  = H*CM.Ay(:,i);
                Xvec  = (Xvec  + CM.pixelshift(1)/CM.NormScale)*CM.NormScale;
                Yvec  = (Yvec  + CM.pixelshift(2)/CM.NormScale)*CM.NormScale;
                CM.MS.Data.X(i,:) = Xvec';
                CM.MS.Data.Y(i,:) = Yvec';
            end
        end
        
        
        function fit_zp (CM)
            MagErr = 0.001*ones(size(CM.MS.Data.(CM.MagColName)));
            CM.MS.addMatrix(MagErr,'MagErr');
            res = lcUtil.zp_meddiff(CM.MS,'MagField',CM.MagColName,'MagErrField','MagErr',...
                'MinNepoch',numel(CM.MS.JD)*CM.ApearenceFactor*0.6,'UseWMedian',false);
            CM.zp = res.FitZP';
            
        end
        
        
        function fix_zp (CM)
            CM.MS.Data.(CM.MagColName)= CM.MS.Data.(CM.MagColName)-CM.zp;
            
        end
        
        
        
        function fit_pm (CM,Args)
            arguments
                CM
                Args.laterFlag=false;
                Args.JDlater=2458150 ;
            end

            %H =
            CM.pm_x=[];
            CM.pm_y=[];
            CM.pm_x_err=[];
            CM.pm_y_err=[];
            H = [ones(size(CM.MS.JD)),CM.MS.JD - CM.RefJD];
            CM.revert_shift_scale;
            for Iobj = 1:CM.MS.Nsrc
                if (Args.laterFlag)
                    Flag = ~isnan(CM.MS.Data.X(:,Iobj)) & ~isnan(CM.MS.Data.Y(:,Iobj)) & CM.MS.JD>Args.JDlater  ;
                else
                    Flag = ~isnan(CM.MS.Data.X(:,Iobj)) & ~isnan(CM.MS.Data.Y(:,Iobj)) ;
                end
                Xt = CM.MS.Data.X(Flag,Iobj);
                Yt = CM.MS.Data.Y(Flag,Iobj);
                flux = CM.MS.Data.FLUX_PSF(Flag,Iobj);
                chi2dof= CM.MS.Data.PSF_CHI2DOF(Flag,Iobj);
                w= (flux.^2./chi2dof);
                Ht = H(Flag,:);
                fwhm = CM.MS.Data.fwhm(Flag,Iobj);
                fit_parx= lscov(H(Flag,:),CM.MS.Data.X(Flag,Iobj),w);
                fit_pary= lscov(H(Flag,:),CM.MS.Data.Y(Flag,Iobj),w);
                
                [~ ,rm_clip_x] = rmoutliers(Ht*fit_parx - Xt,'percentiles',[10,90]);
                [~ ,rm_clip_y] = rmoutliers(Ht*fit_pary - Yt,'percentiles',[10,90]);
                clip = rm_clip_y | rm_clip_x;
                
                [CM.pm_x(:,Iobj),CM.pm_x_err(:,Iobj)] = lscov(Ht(~clip,:),Xt(~clip),w(~clip));
                [CM.pm_y(:,Iobj),CM.pm_y_err(:,Iobj)] = lscov(Ht(~clip,:),Yt(~clip),w(~clip));
                
            end
        end
        
        
        
        function fit_pm_plx(CM,Args)
            % Fit proper motion and parallaxes for the relative astrometry
            % solution, i.e, measuren in pixels where the X axis is
            % parallel to the right ascesion and Y to declination.
            arguments
                CM
                Args.FitPlx =true;
                Args.ra_dec_ref=[]; % for pixesl no WCS solution
                Args.SigmaClip=false;
                Args.RefJD; % default is j2000
            end

            
            [Ecoo,~] = celestial.SolarSys.calc_vsop87(CM.MS.JD, 'Earth', 'e', 'E');
            %[Res,Hra,Hdec,JD] = ml.astrometry.fit_pm_parallax_pix(Coo,JD,'ra_dec_ref',Args.ra_dec_ref,'FitPlx',Args.FitPlx);
            for Iobj = 1:CM.MS.Nsrc
                
                Flag = ~isnan(CM.MS.Data.X(:,Iobj)) & ~isnan(CM.MS.Data.Y(:,Iobj));
                Xt = CM.MS.Data.X(Flag,Iobj);
                Yt = CM.MS.Data.Y(Flag,Iobj);
                Coo = [Xt,Yt];
                jd = CM.MS.JD(Flag);
                [Res,~,Hra,Hdec,jd] = ml.astrometry.fit_pm_parallax_pix(Coo,jd ,'ra_dec_ref',Args.ra_dec_ref,'FitPlx',Args.FitPlx,'Ecoo',Ecoo(:,Flag));
                
                %fwhm = CM.MS.Data.fwhm(Flag,Iobj);
                %fit_parx= lscov(H(Flag,:),CM.MS.Data.X(Flag,Iobj),1./fwhm.^2);
                %fit_pary= lscov(H(Flag,:),CM.MS.Data.Y(Flag,Iobj),1./fwhm.^2);
                
                [~ ,rm_clip_x] = rmoutliers(Hra*Res - Xt,'percentiles',[5,95]);
                [~ ,rm_clip_y] = rmoutliers(Hdec*Res - Yt,'percentiles',[5,95]);
                clip = rm_clip_y | rm_clip_x;
                
                
                Coo = Coo(~clip,:);
                jd = jd(~clip);
                
                ecoo_temp = Ecoo(:,Flag);
                ecoo_temp = Ecoo(:,~clip);
                [Res,Err] = ml.astrometry.fit_pm_parallax_pix(Coo,jd ,'ra_dec_ref',Args.ra_dec_ref,'FitPlx',Args.FitPlx,'Ecoo',ecoo_temp);
                %CM.pm_x(:,Iobj) = Res(1:2);
                %CM.pm_x_err(:,Iobj) = Err(1:2);
                %CM.pm_y(:,Iobj) = Res(3:4);
                %CM.pm_y_err(:,Iobj) = Err(3:4);
                CM.plx_par(Iobj,:) = Res';
                CM.plx_par_err(Iobj,:) = Err';
                %[CM.pm_x(:,Iobj),CM.pm_x_err(:,Iobj)] = lscov(Ht(~clip,:),Xt(~clip),1./fwhm(~clip).^2);
                %[CM.pm_y(:,Iobj),CM.pm_y_err(:,Iobj)] = lscov(Ht(~clip,:),Yt(~clip),1./fwhm(~clip).^2);

            
            end
            
            
            
        end
        
        
        
    end
    
    
    
    methods 
        
        function main_run(CM,Args)
            
            arguments
                
               CM;
               %Args.ra_dec_ref= [celestial.coo.convertdms('17:52:38.74','SH','r')]
               Args.FitPlx = false;
               Args.ra_dec_ref=[];
            end
            
            
            %CM.MS.JD=[CM.AstCat.JD]';
            
            disp(['Finish catMatch construction'])
            CM.fit_pattern; CM.clear_pattern_failed;CM.apply_pattern;
            %CM.fit_pattern_match; CM.clear_pattern_failed;
            disp(['Finish pattern match'])
            try
                CM.MS.Data = rmfield(CM.MS.Data,'MagErr');
            catch
                do_nothing=0;
            end
            disp(['Start matching '])
            CM.matchCat; CM.clear_unmatched;
            %CM.MS.addMatrix(CM.AstCat,CM.RetrunCols);
            %CM.clear_unmatched;
            disp(['finish matching '])
            
            %CM.fit_pm;
            %err_pattern= [CM.pm_x_err(1,:)',CM.pm_x_err(2,:)',CM.pm_y_err(1,:)',CM.pm_y_err(2,:)'];
            CM.fit_affine; CM.apply_affine;
            CM.fit_pm;
            %CM.fit_affine('GlobalRef',true,'OnlyMagRange',true);
            %CM.apply_affine;
            if Args.FitPlx
                CM.fit_pm_plx('ra_dec_ref',Args.ra_dec_ref);
            else
                CM.fit_pm;
            end
            
            CM.fit_zp;CM.fix_zp;
            
            
            
        end
            
        
        
    end
    
    methods
        
        
        
        function RefCat_ast = create_reference(CM,jd,Args)
            
            arguments
               CM;
               jd;
               Args.flag_pm_err=false;
            end
            jd0 = CM.RefJD;
            FLUX_PSF = mean(CM.MS.Data.FLUX_PSF,'omitnan')';
            MAG_PSF = mean(CM.MS.Data.MAG_PSF,'omitnan')';
            PSF_CHI2DOF = mean(CM.MS.Data.PSF_CHI2DOF ,'omitnan')';
            H = ones(size(MAG_PSF)).*[1,(jd - jd0)];
            X = diag(H*CM.pm_x);
            Y = diag(H*CM.pm_y);
            if Args.flag_pm_err
                flag = CM.get_flag_pm_err;
                X=X(flag); Y=Y(flag);MAG_PSF=MAG_PSF(flag);
                FLUX_PSF= FLUX_PSF(flag);
            end
            RefCat_ast= AstroCatalog({[X,Y,MAG_PSF,FLUX_PSF,PSF_CHI2DOF]},'ColNames',{'X','Y','MAG_PSF','FLUX_PSF','PSF_CHI2DOF'});
            
                
            
            
            
        end
        
        function H = distortion_design_matrix(CM,epochInd,Order,Args)
            %
            arguments
                CM
                epochInd =1;
                Order=3;
                Args.X=[];
                Args.Y=[];
                Args.flag_pm_err=false;
            end
            if (isempty(Args.X)&& isempty(Args.Y))
                
                if Args.flag_pm_err
                    flag_pm_err = CM.get_flag_pm_err;
                    X = (CM.MS.Data.('X')(epochInd,flag_pm_err)' -CM.pixelshift(1))/CM.NormScale;
                    Y = (CM.MS.Data.('Y')(epochInd,flag_pm_err)' -CM.pixelshift(2))/CM.NormScale;
                else
                    X = (CM.MS.Data.('X')(epochInd,:)' -CM.pixelshift(1))/CM.NormScale;
                    Y = (CM.MS.Data.('Y')(epochInd,:)' -CM.pixelshift(2))/CM.NormScale;
                end
            else
                X = Args.X;
                Y = Args.Y;
            end
            
            switch Order
                
                %case 3
                    
                    % Get affine matrix
                    %H = CM.designMatrix(epochInd,Cols, {[],1,1});
                    % Calculate the entire orders
                    %H=[ones(size(X)),X,Y,X.^2,Y.^2,X.*Y,X.^3,Y.^3,X.^2.*Y,X.*Y.^2];
                    
                case 2 
                    % H = [P00,P10,P01,P20,P02,P11];
                    H = [ones(size(X)),X,Y,(3*X.^2) - 1,(3*Y.^2) - 1,X.*Y];
                case 3
                    % H = [P00,P10,P01,P20,P02,P11,P30,P03,P21,P12];
                    H = [ones(size(X)),X,Y,(3*X.^2) - 1,(3*Y.^2) - 1,X.*Y,(5*X.^3) - (3*X),...
                        (5*Y.^3) - (3*Y),Y.*((3*X.^2) - 1),X.*((3*Y.^2) - 1)];
                    
                
                
                case 4
                    % H = [P00,P10,P01,P20,P02,P11,P30,P03,P21,P12,P40,P04,P31,P13,P22];
                    H = [ones(size(X)),X,Y,(3*X.^2) - 1,(3*Y.^2) - 1,X.*Y,(5*X.^3) - (3*X),...
                        (5*Y.^3) - (3*Y),Y.*((3*X.^2) - 1),X.*((3*Y.^2) - 1),...
                        (35*X.^4)/8 - (15*X.^2)/4 + 3/8, (35*Y.^4)/8 - (15*Y.^2)/4 + 3/8,...
                        -Y.*((3*X)/2 - (5*X.^3)/2), -X.*((3*Y)/2 - (5*Y.^3)/2),...
                        ((3*X.^2)/2 - 1/2).*((3*Y.^2)/2 - 1/2)];
                        
                    
                    
                    
                
            end
            
            
            
        end
        
        
        
        
        function flag = get_flag_pm_err(CM,Args)
            
            arguments 
               CM;
               Args.pm_err_prctl;
               
                
                
            end
        
            flag= CM.pm_x_err(1,:)'<prctile(CM.pm_x_err(1,:)',CM.pm_err_prctl)...
                | CM.pm_y_err(1,:)'<prctile(CM.pm_y_err(1,:)',CM.pm_err_prctl);
            
            
        end
        
        function set_outliers_nan(CM,flag)
            % Set the true in flag to be nan in all MatchedSources data
            % fields.
            
            fields =fieldnames(CM.MS.Data);
            
            for Ifield=1:numel(fields)
                CM.MS.Data.(fields{Ifield})(flag) = nan;
            end
            
            
            
        end
        
        
        function Ind = find_event_ind(CM,Args)
            
            % Find the event index in MacthedSources
            
            
            arguments
                CM
                Args.event_xy =  [150,150];
                
            end
            
            %X = (CM.MS.Data.X*CM.NormScale+CM.pixelshift(1));
            %Y = (CM.MS.Data.Y*CM.NormScale+CM.pixelshift(2));
            CM = revert_shift_scale(CM);
            X = (CM.MS.Data.X);
            Y = (CM.MS.Data.Y);
            
            
            XY = [nanmean(X)',nanmean(Y)'];
            D = sqrt(nansum((XY-Args.event_xy).^2,2));
            [~,Ind] = min(D(D>0));
            
            
            
            
        end
        
        
        
        function XYtag = apply_distortion_XY(CM,XY)
            for i=1:numel(CM.MS.JD)
                %Xvec = [CM.MS.Data.X(i,:);CM.MS.Data.Y(i,:);ones(size(CM.MS.Data.X(i,:)))];
                H = CM.distortion_design_matrix('X',XY(:,1),'Y',XY(:,2));
                Xvec  = H*CM.Ax(:,i);
                Yvec  = H*CM.Ay(:,i);
                
                XYtag(i,1) = Xvec';
                XYtag(i,2) = Yvec';
            end
        end
        
        
        
        
        function [Cat] = MatchedSources2meanCat(CM,Args)
            
            arguments
                CM;
                Args=[];
            end
            fields =fieldnames(CM.MS.Data);
            CatMat= [];
            Cat =AstroCatalog;
            for Ifield=1:numel(fields)
                CatMat(:,Ifield) = mean(CM.MS.Data.(fields{Ifield}),'omitnan')';
            end
            Cat=AstroCatalog;
            Cat.Catalog = CatMat;
            Cat.ColNames  =fields;
        end
        
        
        
        
        function Flag = IsInMagRange(CM,mag,Args)
            
            arguments
                CM;
                mag;
                Args=[];
            end
            
            Flag= CM.mag_range(1)<= mag & mag<= CM.mag_range(2) ;
            
            
            
        end
        
        
        
        function Res = calculate_Delta_chi(CM)
            
            H_pm= [ones(size(CM.MS.JD)),CM.MS.JD - CM.RefJD];
            H_par= [ones(size(CM.MS.JD)),CM.MS.JD - CM.RefJD,(CM.MS.JD - CM.RefJD).^2];
            H_mean = [ones(size(CM.MS.JD))];
            CM.revert_shift_scale;
            Res.pm_x=[];
            Res.pm_y=[];
            Res.par_x = [];
            Res.mean_x=[];
            for Iobj = 1:CM.MS.Nsrc
                
                Flag = ~isnan(CM.MS.Data.X(:,Iobj)) | ~isnan(CM.MS.Data.Y(:,Iobj));
                Xt = CM.MS.Data.X(Flag,Iobj);
                Yt = CM.MS.Data.Y(Flag,Iobj);
                
                
                H_pm_t = H_pm(Flag,:);
                H_par_t = H_par(Flag,:);
                %H_mean_t = H_mean(Flag,:);
                fwhm = CM.MS.Data.fwhm(Flag,Iobj);
                %fit_parx= lscov(H_pm_t,Xt,1./fwhm.^2);
                %fit_pary= lscov(H_pm_t,Yt,1./fwhm.^2);
                
                %[~ ,rm_clip_x] = rmoutliers(H_pm_t *fit_parx - Xt);
                %[~ ,rm_clip_y] = rmoutliers(H_pm_t *fit_pary - Yt);
                
                %clip = rm_clip_y | rm_clip_x;
                jd_t= CM.MS.JD(Flag) - CM.RefJD;
                %[xmid, ymid, loc, N] =  ut.calc_bin_fun(jd_t(~clip),Xt(~clip),'Nbins',100,'fun',@nanmean,'MinNinBin',4);
                %[xmid_std, ymid_std, loc, N] =  ut.calc_bin_fun(jd_t(~clip),Xt(~clip),'Nbins',100,'fun',@tools.math.stat.rstd,'MinNinBin',4);
                [xmid,mean_bin,std_bin,loc,N]= ut.calc_bin_mean_std(jd_t,(CM.MS.Data.X(:,92)-nanmean(CM.MS.Data.X(:,92)))*0.4*1000,'Nbins',100);
                flag_bin = ~(isnan(mean_bin) | isnan(std_bin));
                H_pm_t = [ones(size(xmid(flag_bin))),xmid(flag_bin)];
                H_par_t = [ones(size(xmid(flag_bin))),xmid(flag_bin),xmid(flag_bin).^2];
                [Res.pm_x(:,Iobj)] = lscov(H_pm_t,mean_bin(flag_bin),1./std_bin(flag_bin).^2);
                Res.par_x(:,Iobj) = lscov(H_par_t ,mean_bin(flag_bin),1./std_bin(flag_bin).^2);
                Res.nobs(Iobj,1)= numel(xmid(flag_bin));
                Res.chi2_pm(Iobj,1)= sum(((mean_bin(flag_bin)- H_pm_t *Res.pm_x(:,Iobj))./(std_bin(flag_bin))).^2);
                Res.chi2_par(Iobj,1)= sum(((mean_bin(flag_bin)- H_par_t *Res.par_x(:,Iobj))./(std_bin(flag_bin))).^2);
                %[Res.pm_x(:,Iobj)] = lscov(H_pm_t (~clip,:),Xt(~clip),1./fwhm(~clip).^2);
                %[Res.pm_y(:,Iobj)] = lscov(H_pm_t (~clip,:),Yt(~clip),1./fwhm(~clip).^2);
                %Res.par_x(:,Iobj) = lscov(H_par_t (~clip,:),Xt(~clip),1./fwhm(~clip).^2);
                %Res.mean_x(:,Iobj) = lscov(H_mean_t(~clip,:),Xt(~clip),1./fwhm(~clip).^2);
                %Res.nobs(Iobj,1)= numel(Xt(~clip));
                %Res.chi2_pm(Iobj,1)= sum((Xt(~clip)- H_pm_t (~clip,:)*Res.pm_x(:,Iobj)).^2);
                %Res.chi2_par(Iobj,1)= sum((Xt(~clip)- H_par_t (~clip,:)*Res.par_x(:,Iobj)).^2);
                %Res.chi2_mean(Iobj,1)= sum((Xt(~clip)- H_mean_t (~clip,:)*Res.mean_x(:,Iobj)).^2);
                
            end
            
        end
        
        
        
        
        function isout = pm_outliers(CM)
            % Return the outliers from the proper motion curve. The 
            % function use using moving median to decleare outlier.
            % 
            %
            % Input:
            %       CM -  object with proper motion solution for each
            %       object. Better use after first affine transformation.
            %       
            %       'Thresh' - number of median absolute devation(MAD) the
            %       to clip
            
            isout=false(size(CM.MS.Data.X));
            
            H = [ones(size(CM.MS.JD)),CM.MS.JD-CM.RefJD];
            
            for i =1:numel(CM.MS.Data.X(1,:))
                
                outx=isoutlier(H*CM.pm_x(:,i)-CM.MS.Data.X(:,i),'movmedian',30,'ThresholdFactor',2);
                outy=isoutlier(H*CM.pm_y(:,i)-CM.MS.Data.Y(:,i),'movmedian',30,'ThresholdFactor',2);
                isout(:,i) = outx|outy;
                
            end
            
        
            
            
            
        end
        
        
        function H= pm_design_mat(CM)
            
            
            
            
            
            
            H = [ones(size(CM.MS.JD)),CM.MS.JD-CM.RefJD];
        end
        
        
        
        function fit_pattern_match(CM,Args)
            
            % Fit pattren of the AstroCatalog array with respect to the
            % reference image, This procedure is rough with steps of 0.1
            % pixels.
            
            arguments
                CM;
                %IndCat (1,1) numeric;
                Args.SearchRadius=3;
                Args.HistRotEdges= (-90:0.2:90);
                Args.RangeX = [-100.5,100.5];
                Args.RangeY = [-100.25,100.25];
                Args.StepX = 0.5;
                Args.StepY = 0.5;
                Args.MatchRaiud = 1;
                
                Args.SearchRadius_sec=1;
                Args.HistRotEdges_sec= (-1:0.002:1);
                Args.RangeX_sec = [-1.5,1.5];
                Args.RangeY_sec = [-1.25,1.25];
                Args.StepX_sec = 0.01;
                Args.StepY_sec = 0.01;
                
            end
            
            
            for IndCat=1:numel(CM.AstCat)
                try
                    [II] = imProc.trans.fitPattern(CM.RefCat,CM.AstCat(IndCat),'StepX',Args.StepX ,'StepY',Args.StepY ,...
                        'RangeX',Args.RangeX ,'RangeY',Args.RangeY ,'SearchRadius',Args.SearchRadius,'HistRotEdges',Args.HistRotEdges,...
                        'MaxMethod','max1');
                    [NewX,NewY]=imUtil.cat.affine2d_transformation(CM.AstCat(IndCat).Catalog,II.Sol.AffineTran{1},'+'...
                        ,'ColX',CM.AstCat(IndCat).colname2ind('X'),'ColY',CM.AstCat(IndCat).colname2ind('Y'));
                    CM.AstCat(IndCat).Catalog(:,CM.AstCat(IndCat).colname2ind('X'))=NewX;
                    CM.AstCat(IndCat).Catalog(:,CM.AstCat(IndCat).colname2ind('Y'))=NewY;
                    
                    Matched = imProc.match.matchedReturnCat(CM.RefCat,CM.AstCat(IndCat),'CooType','pix','Radius'...
                        ,Args.MatchRaiud);
                    XY1 = Matched.getCol({'X','Y'});
                    XY2 = CM.RefCat.getCol({'X','Y'});
                    
                    chi2dof = Matched(1).getCol('PSF_CHI2DOF');
                    %flag_pdf_fit = chi2dof>10;
                    
                    D= sqrt((XY1(:,1) - XY2(:,1)').^2 + (XY1(:,2) - XY2(:,2)').^2);
                    isoutx = isoutlier(XY1(:,1)- XY2(:,1));%,'percentile',[10,90]);
                    isouty = isoutlier(XY1(:,2)- XY2(:,2));%,'percentile',[10,90]);
                    
                    
                    %flag_dist = ones(size(sum(D<15,2)==1));
                    %flag_dist = sum(D<3,2)==1;
                    
                    % First selection
                    
                    Matched.Catalog(~flag_dist | isoutx | isouty ,:) = ...
                        nan(size(Matched.Catalog(~flag_dist | isoutx | isouty ,:)));
                    
                    [II] = imProc.trans.fitPattern(CM.RefCat,Matched,'StepX',Args.StepX_sec ,'StepY',Args.StepY_sec ,...
                        'RangeX',Args.RangeX_sec ,'RangeY',Args.RangeY_sec,'SearchRadius',Args.SearchRadius_sec,'HistRotEdges',Args.HistRotEdges_sec,...
                        'MaxMethod','max1');
                    [NewX,NewY]=imUtil.cat.affine2d_transformation(Matched.Catalog,II.Sol.AffineTran{1},'+'...
                        ,'ColX',CM.AstCat(IndCat).colname2ind('X'),'ColY',CM.AstCat(IndCat).colname2ind('Y'));
                    Matched.Catalog(:,Matched.colname2ind('X'))=NewX;
                    Matched.Catalog(:,Matched.colname2ind('Y'))=NewY;
                    CM.AstCat(IndCat) = Matched;
                    
                    
                    
                    
                    CM.PatternMat{IndCat} =II.Sol.AffineTran;
                catch
                    CM.Pattern_failed= [CM.Pattern_failed,IndCat];
                    CM.PatternMat{IndCat}= {};
                end
            end
            
            
        end
    end
end