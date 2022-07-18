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
        NormScale =100;
        pix2mas
        pixelshift = [150,150];
        isPixScaled = 0;
        % properties for MatchCat
        MatchRadius = 3; %
        %         RetrunCols = {'X','Y','MAG_CONV_'...
        %             ,'SN_1','FLUX_CONV_1','MAGERR_CONV_1'...
        %            };%,'MAGERR_PSF'};
        %RetrunCols = {'X','Y','MAG_PSF' ,'SN_3' ,'FLUX_PSF','MAGERR_APER_3'...
        RetrunCols = {'X','Y','MAG_PSF' ,'FLUX_PSF'...
            ,'fwhm','secz','pa','PSF_CHI2DOF'};%,'MAGERR_PSF'};
        Match_Summary;
        Match_N_Ep;
        MS = MatchedSources;
        MagColName = 'MAG_PSF';
        SNColName = 'SN_3';
        FluxColName = 'FLUX_PSF';
        MagErrColName = 'MAGERR_APER_3';
        MS_fields = {'X','Y','MAG_PSF' ,'SN_3' ,'FLUX_PSF','MAGERR_APER_3' }
        ApearenceFactor=0.7;
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
        DistortionOrder=3;
        Ax=[];
        Ay=[];
        mag_range=[10,13];
        N_dist_outliers=[];
        rms_dist_fit=[];
        outliers_in_dist_fit=[];
        % zero point fiting
        zp=[]
        
        % proper motion
        pm_x=[]
        pm_y=[]
        pm_x_err=[]
        pm_y_err=[]
        RefJD = celestial.time.date2jd([2018,1,1]);
    end
    
    methods
        % Constructor
        
        function CM = catMatch(AstCat)
            
            CM.AstCat= AstCat;
            
            
        end
        
        
        
    end
    
    methods
        % setters and getters
        
        
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
    
    
    methods
        
        %Data collection, match and fit pattern
        function matchCat(CM)
            %[m_astcat] =imProc.match.match(CM.AstCat,CM.RefCat,'Radius',CM.MatchRadius,'RadiusUnits','pix');
            
            %[CM.MatchMat, Summary, N_Ep, Units] = imProc.match.matched2matrix(m_astcat, CM.RetrunCols);
            XYcol = CM.AstCat(1).colname2ind({'X','Y'});
            nanCat = nan(size(CM.RefCat.Catalog));
            
            [Result,~,~] = imProc.match.unifiedSourcesCatalog(CM.AstCat,'CooType','pix','Radius',CM.MatchRadius,'ColNamesX','X',...
                'ColNamesY','Y');
            Matched = imProc.match.matchedReturnCat(Result,CM.AstCat,'CooType','pix','Radius',CM.MatchRadius);
            
            %[MatchedObj, UnMatchedObj, TruelyUnMatchedObj]= imProc.match.match(CM.AstCat,CM.RefCat,'ColCatX',XYcol(1)...
            %         ,'ColCatY',XYcol(2),'ColRefX',XYcol(1),'ColRefY',XYcol(2),'CooType','pix','Radius',CM.MatchRadius);
            %flagNan = ~isnan(ResM.MatchedInd(:,1));
            %temp(ResM.MatchedInd(:,1),:) = CM.AstCat(IndCat).Catalog(ResM.MatchedInd(:,1),:);
            
            %CM.AstCat(IndCat).Catalog = temp;
            
            
            CM.MS.addMatrix(Matched,CM.RetrunCols);
            %[CM.MS, Matched] = unifiedCatalogsIntoMatched(CM.MS, MatchedObj,'CooType','pix','MatchedColums',CM.MS_fields);
            
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
                        'RangeX',[-100.5,100.5],'RangeY',[-100.25,100.25],'SearchRadius',7,'HistRotEdges',(-90:0.2:90),...
                        'MaxMethod','max1');
                    
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
    
    
    methods
        % Fit transformations
        
        function CM= fit_affine(CM)
            
            X = CM.MS.Data.X;
            Y = CM.MS.Data.Y;
            %SN = CM.MS.Data.(CM.SNColName);
            RefX = X(1,:);
            RefY = Y(1,:);
            for i =1:numel(CM.AstCat)
                %H = [X(i,:)',Y(i,:)',ones(size(RefX'))];
                H = CM.designMatrix(i,CM.AffineCols , CM.AffineFuns);
                Flag = ~isnan(X(i,:)')&~isnan(Y(i,:)') &~isnan(RefX')...
                    &~isnan(RefY');
                Ax = H(Flag,:)\RefX(Flag)';
                Ay = H(Flag,:)\RefY(Flag)';
                isoutx = isoutlier(H(Flag,:)*Ax-RefX(Flag)');
                isouty= isoutlier(H(Flag,:)*Ay-RefX(Flag)');
                Ht = H(Flag,:);
                Xt = RefX(Flag)';
                Yt = RefY(Flag)';
                isout= isoutx|isouty;
                %isout= false(size(isouty));
                Ax = Ht(~isout,:)\Xt(~isout);
                Ay = Ht(~isout,:)\Yt(~isout);
                CM.AffineMat{i} = [Ax';Ay';0,0,1];
                
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
        
        function CM = fit_distortion(CM,Flux)
            
            arguments
                CM
                Flux = nanmean(CM.MS.Data.(CM.FluxColName))';
                
            end
            %if all(Flux==1)
            %    Flux = ones(size(nanmean(CM.MS.Data.(CM.FluxColName))'));
            %end
            % Fit for distortion using polynomials.
            
            
            %RefX = CM.MS.Data.X(1,:)';
            %RefY = CM.MS.Data.Y(1,:)';
            %[RefX,RefY]=CM.refXY;
            RefCat_fl = CM.create_reference(CM.MS.JD(1));
            Flux = RefCat_fl.getCol('FLUX_PSF');
            CM.outliers_in_dist_fit=false(size(CM.MS.Data.X));
            for i = 1:numel(CM.MS.JD)
                %X = CM.MS.Data.('X')(i,:)';
                %Y = CM.MS.Data.('Y')(i,:)';
                
                RefCat_ast = CM.create_reference(CM.MS.JD(i));
                RefX=RefCat_ast.getCol('X')-CM.pixelshift(1)/CM.NormScale;
                RefY=RefCat_ast.getCol('Y')-CM.pixelshift(2)/CM.NormScale;
                H = CM.distortion_design_matrix(i,CM.DistortionOrder);
                
                Flag = ~any(isnan(H),2) &~isnan(RefX)...
                    &~isnan(RefY) & CM.IsInMagRange(RefCat_ast.getCol('MAG_PSF'));
                CM.outliers_in_dist_fit(i,~Flag)=false;
                
                H= H(Flag,:);
                XrefT = RefX(Flag);
                YrefT = RefY(Flag);
                FluxT = Flux(Flag);
                ax = lscov(H,XrefT ,FluxT.^2);
                ay = lscov(H,YrefT ,FluxT.^2);
                
                isout= isoutlier(H*ax-CM.MS.Data.X(i,Flag)') | isoutlier(H*ay-CM.MS.Data.Y(i,Flag)');
                CM.N_dist_outliers(i)=sum(isout);
                CM.outliers_in_dist_fit(i,Flag)=isout';
                CM.Ax(:,i) = lscov(H(~isout,:),XrefT(~isout) ,FluxT(~isout).^2);
                CM.Ay(:,i) = lscov(H(~isout,:),YrefT(~isout) ,FluxT(~isout).^2);
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
        
        
        
        
        
        function apply_distortion(CM)
            for i=1:numel(CM.MS.JD)
                %Xvec = [CM.MS.Data.X(i,:);CM.MS.Data.Y(i,:);ones(size(CM.MS.Data.X(i,:)))];
                H = CM.distortion_design_matrix(i,CM.DistortionOrder);
                Xvec  = H*CM.Ax(:,i);
                Yvec  = H*CM.Ay(:,i);
                
                CM.MS.Data.X(i,:) = Xvec';
                CM.MS.Data.Y(i,:) = Yvec';
            end
        end
        
        
        function fit_zp (CM)
            MagErr = 0.001*ones(size(CM.MS.Data.(CM.MagColName)));
            CM.MS.addMatrix(MagErr,'MagErr');
            res = lcUtil.zp_meddiff(CM.MS,'MagField',CM.MagColName,'MagErrField','MagErr',...
                'MinNepoch',numel(CM.MS.JD)*CM.ApearenceFactor*0.6);
            CM.zp = res.FitZP;
            
        end
        
        
        function fix_zp (CM)
            CM.MS.Data.(CM.MagColName)= CM.MS.Data.(CM.MagColName)+CM.zp;
            
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
                Ht = H(Flag,:);
                fwhm = CM.MS.Data.fwhm(Flag,Iobj);
                fit_parx= lscov(H(Flag,:),CM.MS.Data.X(Flag,Iobj),1./fwhm.^2);
                fit_pary= lscov(H(Flag,:),CM.MS.Data.Y(Flag,Iobj),1./fwhm.^2);
                
                [~ ,rm_clip_x] = rmoutliers(Ht*fit_parx - Xt);
                [~ ,rm_clip_y] = rmoutliers(Ht*fit_pary - Yt);
                clip = rm_clip_y | rm_clip_x;
                
                [CM.pm_x(:,Iobj),CM.pm_x_err(:,Iobj)] = lscov(Ht(~clip,:),Xt(~clip),1./fwhm(~clip).^2);
                [CM.pm_y(:,Iobj),CM.pm_y_err(:,Iobj)] = lscov(Ht(~clip,:),Yt(~clip),1./fwhm(~clip).^2);
                
            end
        end
        
        
        
        
        
    end
    
    
    
    
    
    methods
        
        
        
        function RefCat_ast = create_reference(CM,jd)
            
            jd0 = CM.RefJD;
            FLUX_PSF = mean(CM.MS.Data.FLUX_PSF,'omitnan')';
            MAG_PSF = mean(CM.MS.Data.MAG_PSF,'omitnan')';
            H = ones(size(MAG_PSF)).*[1,(jd - jd0)];
            X = diag(H*CM.pm_x);
            Y = diag(H*CM.pm_y);
            RefCat_ast= AstroCatalog({[X,Y,MAG_PSF,FLUX_PSF]},'ColNames',{'X','Y','MAG_PSF','FLUX_PSF'});
            
            
            
            
        end
        
        function H = distortion_design_matrix(CM,epochInd,Order,Args)
            %
            arguments
                CM
                epochInd =1
                Order=3
                Args.X=[];
                Args.Y=[];
            end
            if (isempty(Args.X)&& isempty(Args.Y))
                
                X = CM.MS.Data.('X')(epochInd,:)';
                Y = CM.MS.Data.('Y')(epochInd,:)';
            else
                X = Args.X;
                Y = Args.Y;
            end
            
            switch Order
                
                case 3
                    
                    % Get affine matrix
                    %H = CM.designMatrix(epochInd,Cols, {[],1,1});
                    % Calculate the entire orders
                    H=[ones(size(X)),X,Y,X.^2,Y.^2,X.*Y,X.^3,Y.^3,X.^2.*Y,X.*Y.^2];
                    
                case 4
                    H=[ones(size(X)),X,Y,X.^2,Y.^2,X.*Y,X.^3,Y.^3,X.^2.*Y,X.*Y.^2,...
                        X.^4,Y.^4,X.^2.*Y.^2,X.*Y.^3];
                    
            end
            
            
            
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
            
            Flag= CM.mag_range(1)<mag & mag< CM.mag_range(2) ;
            
            
            
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
            %       CM - catMatch object with proper motion solution for each
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
    end
end