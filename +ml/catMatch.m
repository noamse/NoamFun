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
        NormScale =300;
        pix2mas
        pixelshift = [300,300];
        isPixScaled = 0;
        % properties for MatchCat
        MatchRadius = 1; %
        %         RetrunCols = {'X','Y','MAG_CONV_'...
        %             ,'SN_1','FLUX_CONV_1','MAGERR_CONV_1'...
        %            };%,'MAGERR_PSF'};
        %RetrunCols = {'X','Y','MAG_PSF' ,'SN_3' ,'FLUX_PSF','MAGERR_APER_3'...
        RetrunCols = {'X','Y','MAG_PSF' ,'FLUX_PSF'...
            ,'fwhm','secz','pa','PSF_CHI2DOF','SN'};%,'MAGERR_PSF'};
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
        OgleCat = AstroCatalog; 
        PatternMat = {};
        Pattern_failed=[];
        FitPattern_step= 0.125;
        FitPattern_range = [-100.125,100.125];
        % propertied for fit_affine
        AffineMat = {};
        AffineCols = {'X','Y',[]};
        AffineFuns = {1,1,[]};
        
        % properties for fit_distortion
        DistortionCols = {[],'X','Y','X','Y'};
        DistortionFuns = {[],1,1,2,2};
        DistortionOrder=2;
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
        Hra_plx= [];
        Hdec_plx=[];
        % Ogle match flags
        matched_flag_ogle_cat=[];
        matched_flag_ref_cat=[]; 
        
        % Chromatic fit
        C_med= 0;
        % H = [1,C*secz*cos(pa), C*secz*sin(pa)];
        % fitted with resx,resy taken from resid_per_obs_x\y
        dy_chrom_par=[]; 
        dx_chrom_par= [];% 
    end
    
    methods % Constructor
        

        function CM = catMatch(AstCat,Args)
            arguments
               AstCat;
               Args.FilesDirectory=[];
               Args.MasterName = 'master.txt';
               Args.OgleFileName = 'ogle_cat.mat'
               Args.OgleVarName = 'ogle_cat'
               Args.PropertyName= '';
               Args.PropertyValue = [];
                
            end
            CM.AstCat= AstCat;
            CM.MS=MatchedSources;
            jd = [AstCat.JD];
            CM.MS.JD = jd(:);
            if ~isempty(Args.FilesDirectory)
                try
                    SetVar = readtable([Args.FilesDirectory , Args.MasterName]);
                    CM.NormScale = abs(SetVar.CCDSEC_im_2 - SetVar.CCDSEC_im_1)/2;
                    CM.pixelshift = [CM.NormScale,CM.NormScale];
                    
                catch
                    disp('Could not load master.txt')
                end
                
                try 
                    ogle_file = load([Args.FilesDirectory Args.OgleFileName]);
                    CM.OgleCat = ogle_file.(Args.OgleVarName);
                    CM.OgleCat.Catalog(:,CM.OgleCat.colname2ind({'RA','Dec'})) = ...
                        CM.OgleCat.Catalog(:,CM.OgleCat.colname2ind({'RA','Dec'}))/180*pi;
                catch
                    disp('Could not load ogle catalog')
                    
                end
            end
            if ~isempty(Args.PropertyName)
                try
                    CM.(Args.PropertyName) = Args.PropertyValue;
                catch
                    disp('Could not assert the property change')
                    
                end
            end
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
        
        
        function matchCat(CM,Args)
            arguments
               CM;
               Args.MatchRadius = 2; 
                
            end
            
            Matched = imProc.match.matchedReturnCat(CM.RefCat,CM.AstCat,'CooType','pix','Radius',Args.MatchRadius);
            
            CM.MS.addMatrix(Matched,CM.RetrunCols);

            
        end
        
        function clear_unmatched(CM)
            % clear unmatched sources using an appearence criteria
            
            %CM.unMatchFlag =sum(~isnan(CM.MS.Data.X))>numel(CM.MS.JD)*CM.ApearenceFactor;
            CM.unMatchFlag =sum(~isnan(CM.MS.Data.X))> prctile(sum(~isnan(CM.MS.Data.X)),20);
            CM.MS.Data= flag_struct_field(CM.MS.Data,CM.unMatchFlag ,'FlagByCol',true);
            
            Nsrc_epoch= sum(~isnan(CM.MS.Data.MAG_PSF),2);  
            MAD_std= mad(Nsrc_epoch);
            epochs_flag = Nsrc_epoch > median(Nsrc_epoch) - 2*MAD_std | Nsrc_epoch >30;%& Nsrc_epoch >50;
            CM.MS.Data= flag_struct_field(CM.MS.Data,epochs_flag ,'FlagByCol',false);
            CM.MS.JD = CM.MS.JD(epochs_flag);
            
            

            
            
            
        end
        
        function fit_pattern(CM,Args)
            % Fit pattren of the AstroCatalog array with respect to the
            % reference image, This procedure is rough with steps of 0.1
            % pixels.
            arguments
                CM;
                Args.SearchRadius =1;
                Args.MaxMethod = 'max1';
                Args.Step = 0.25;
                Args.Range = [-30.5,30.5]
                Args.MaxMag = [];
            end
            if ~isempty(Args.MaxMag)
                flagMagRef = CM.RefCat.getCol('RefMag')<Args.MaxMag;
                xyref= CM.RefCat.getCol({'X','Y'});
                xyref = xyref(flagMagRef,:);
            end
            for IndCat = 1:numel(CM.AstCat)
                try
                    if ~isempty(Args.MaxMag)
                        
                        flagMaAstCat= CM.AstCat(IndCat).getCol('RefMag')<17;
                        xyastcat = CM.AstCat(IndCat).getCol({'X','Y'});
                        [II] = imProc.trans.fitPattern(xyref,xyastcat(flagMaAstCat,:),'StepX',Args.Step,'StepY',Args.Step,...
                            'RangeX',Args.Range,'RangeY',Args.Range,'SearchRadius',Args.SearchRadius,'HistRotEdges',(-90:0.2:90),...
                            'MaxMethod',Args.MaxMethod );
                        
                        
                        
                        
                    else
                        
                        
                        [II] = imProc.trans.fitPattern(CM.RefCat,CM.AstCat(IndCat),'StepX',Args.Step,'StepY',Args.Step,...
                            'RangeX',Args.Range,'RangeY',Args.Range,'SearchRadius',Args.SearchRadius,'HistRotEdges',(-90:0.2:90),...
                            'MaxMethod',Args.MaxMethod );
                        [NewX,NewY]=imUtil.cat.affine2d_transformation(CM.AstCat(IndCat).Catalog,II.Sol.AffineTran{1},'+'...
                            ,'ColX',CM.AstCat(IndCat).colname2ind('X'),'ColY',CM.AstCat(IndCat).colname2ind('Y'));
                    end
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
        
        
        
        function cut_mag_chi2(CM,Args)
            % Use after fix_zp
           arguments
              CM;
              Args.MagRange = [10,13.5];
              Args.Chi2Percentile = 50;
              
               
           end
           
           mag_obj = median(CM.MS.Data.MAG_PSF,'omitnan')';
           
           Flag_mag= mag_obj >Args.MagRange(1) ...
               & mag_obj <Args.MagRange(2);
           
           CM.MS.Data= flag_struct_field(CM.MS.Data,Flag_mag,'FlagByCol',true);
          
           chi2obj = median(CM.MS.Data.PSF_CHI2DOF,'omitnan')';
           mag_obj = median(CM.MS.Data.MAG_PSF,'omitnan')';
           Result  = timeseries.binningFast([mag_obj,chi2obj], 0.3,[NaN NaN],{'MidBin', @median, @tools.math.stat.rstd});
           
           interp_chi2 = interp1(Result(:,1),Result(:,2),mag_obj);
           
           Flag_chi = interp_chi2>chi2obj;
           
           CM.MS.Data= flag_struct_field(CM.MS.Data,Flag_chi ,'FlagByCol',true);
           
           
           
           
            
            
            
            
        end
        
        
        
        
        
        
        
    end
    
    
    methods % Fit transformations
        
        function CM= fit_affine(CM,Args)
            
            arguments 
               CM;
               Args.GlobalRef=false;
               Args.WeightByPrcVsMag = false;
               Args.OnlyMagRange=false;
               Args.OnlyOgle = false;
               Args.FlagChi2DOF = false;
               Args.Chi2DOFWeight = false;
               Args.PrctileRange = [20,80];
               Args.OnlyLowExpectedRes=false;
               Args.LowExpectedPrctl = 80;
               Args.FitMaxOgleMag= [];
               Args.UseOgleCat = false;
            end
            
            X = CM.MS.Data.X';
            Y = CM.MS.Data.Y';
            
            %MAG_PSF=CM.MS.Data.MAG_PSF';
            %PSF_CHI2DOF = CM.MS.Data.PSF_CHI2DOF';
            %FLUX_PSF = CM.MS.Data.FLUX_PSF';
            
            %SN = CM.MS.Data.(CM.SNColName);
            RefX = X(:,1);
            RefY = Y(:,1);
            if Args.OnlyOgle
                X= X(CM.matched_flag_ref_cat,:);
                Y= Y(CM.matched_flag_ref_cat,:);
                obj_prec = obj_prec(CM.matched_flag_ref_cat);
            end
            for i =1:CM.MS.Nepoch
                
                if Args.GlobalRef
                    RefCat_ast = CM.create_reference(CM.MS.JD(i),'IncludeChi2',Args.Chi2DOFWeight);
                    RefX=RefCat_ast.getCol('X');
                    RefY=RefCat_ast.getCol('Y');
                end
                %H = [X(i,:)',Y(i,:)',ones(size(RefX'))];
                H = CM.designMatrix(i,CM.AffineCols , CM.AffineFuns);
                
                MAG_PSF=CM.MS.Data.MAG_PSF(i,:)';
                
                
                FLUX_PSF = CM.MS.Data.FLUX_PSF(i,:)';
                if Args.Chi2DOFWeight % Based on chi^2
                    PSF_CHI2DOF = CM.MS.Data.PSF_CHI2DOF(i,:)';
                    w = (PSF_CHI2DOF./FLUX_PSF.^2).^(-1);        
                elseif Args.WeightByPrcVsMag % Based on residuals
                    %w = (1./CM.MS.Data.err(i,:)').^2;
                    %w = (1./CM.MS.Data.err(i,:)').^2;
                    w = (1./std(CM.MS.Data.err,'omitnan').^2)';
                else % No weight
                    w = ones(size(FLUX_PSF));
                end
                
                if Args.OnlyOgle
                    
                    RefX= RefX(CM.matched_flag_ref_cat);
                    RefY= RefY(CM.matched_flag_ref_cat);
                    w = w(CM.matched_flag_ref_cat);
                    MAG_PSF = MAG_PSF(CM.matched_flag_ref_cat);
                    H = H(CM.matched_flag_ref_cat,:);
                    Imag = CM.OgleCat.getCol('I');
                    Imag = Imag(CM.matched_flag_ogle_cat);
                end

                    
                %[xmid, ymid, ~,~] =  ut.calc_bin_fun(MAG_PSF,w ,'Nbins',15,'fun',@nanmedian);
                Result = timeseries.binningFast([MAG_PSF,w], 1);
                Result  = timeseries.binningFast([MAG_PSF,1./w], 0.3,[NaN NaN],{'MidBin', @median, @tools.math.stat.rstd});
                %interp_1ow = interp1(Result(:,1),Result(:,2),MAG_PSF);
                %interp_std = interp1(Result(:,1),Result(:,3),MAG_PSF,'nearest');
                %w = w/norm(w,'omitnan');
                
                
                
                %Flag = ~isnan(X(:,i))&~isnan(Y(:,i)) &~isnan(RefX)...
                %    &~isnan(RefY) & ~isnan(w) &w>0 & interp_1ow +interp_std>1./w;
                if isempty(Args.FitMaxOgleMag)
                    Flag = ~isnan(X(:,i))&~isnan(Y(:,i)) &~isnan(RefX)...
                            &~isnan(RefY) & ~isnan(w);
                else
                    Flag = ~isnan(X(:,i))&~isnan(Y(:,i)) &~isnan(RefX)...
                            &~isnan(RefY) & ~isnan(w) & Imag<Args.FitMaxOgleMag;
                end
                
                
                Ht = H(Flag,:);
                Xt = RefX(Flag);
                Yt = RefY(Flag);
                wt = w(Flag);
                ax = lscov(Ht,Xt,wt);
                ay = lscov(Ht,Yt,wt);
                
                isoutx = isoutlier(Ht*ax-Xt,'percentile',Args.PrctileRange);
                isouty= isoutlier(Ht*ay-Yt,'percentile',Args.PrctileRange);
                
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
            for i=1:CM.MS.Nepoch
                
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
        
        
        function CM = fit_distortion(CM,Args)
            % Fit for distortion using polynomials
            arguments
                CM
                Args.GlobalRef=true;
                Args.WeightByPrcVsMag = true;
                Args.OnlyMagRange=false;
                Args.FlagChi2DOF = false;
                Args.Chi2DOFWeight = true;
                Args.PrctileRange = [20,80];
                Args.IncludeChi2 = false;
                Args.flag_pm_err= false;
            end
            
            CM.Ax=[];
            CM.Ay=[];
            
            
            CM.outliers_in_dist_fit=false(size(CM.MS.Data.X));
            
            for i = 1:numel(CM.MS.JD)

                RefCat_ast = CM.create_reference(CM.MS.JD(i),'flag_pm_err',Args.flag_pm_err);
                RefX=(RefCat_ast.getCol('X')-CM.pixelshift(1))/CM.NormScale;
                RefY=(RefCat_ast.getCol('Y')-CM.pixelshift(2))/CM.NormScale;
                H = CM.distortion_design_matrix(i,CM.DistortionOrder,'flag_pm_err',Args.flag_pm_err);
                MAG_PSF=CM.MS.Data.MAG_PSF(i,:)';
                if Args.IncludeChi2

                    
                    PSF_CHI2DOF = CM.MS.Data.PSF_CHI2DOF(i,:)';
                    FLUX_PSF = CM.MS.Data.FLUX_PSF(i,:)';
                    w = (PSF_CHI2DOF./FLUX_PSF.^2).^(-1); 
                    Result  = timeseries.binningFast([MAG_PSF,1./w], 0.3,[NaN NaN],{'MidBin', @median, @tools.math.stat.rstd});
                    interp_1ow = interp1(Result(:,1),Result(:,2),MAG_PSF);
                    interp_std = interp1(Result(:,1),Result(:,3),MAG_PSF,'nearest');
                    Flag = ~isnan(RefX)...
                    &~isnan(RefY) & ~isnan(w) &w>0 & interp_1ow +interp_std>1./w;

                elseif Args.WeightByPrcVsMag
                    
                    w = 1./(CM.pix2mas*CM.MS.Data.err(i,:)').^2;
                    Flag = ~isnan(RefX)  &~isnan(RefY) & ~isnan(w) &w>0 ; 
                    
                else
                    w= ones(size(RefX));
                    Flag= true(size(w));
                end

                
                H= H(Flag,:);
                XrefT = RefX(Flag);
                YrefT = RefY(Flag);
                w= w(Flag);
                ax = lscov(H,XrefT ,w);
                ay = lscov(H,YrefT ,w);
                
                %isout= isoutlier(H*ax-CM.MS.Data.X(i,Flag)','percentile',[10,90]) | isoutlier(H*ay-CM.MS.Data.Y(i,Flag)','percentile',[10,90]);
                isout = false(size(XrefT));
                CM.N_dist_outliers(i)=sum(isout);
                CM.outliers_in_dist_fit(i,Flag)=isout';
                CM.Ax(:,i) = lscov(H(~isout,:),XrefT(~isout) ,w(~isout));
                CM.Ay(:,i) = lscov(H(~isout,:),YrefT(~isout) ,w(~isout));
                Xtest= CM.MS.Data.X(i,Flag)';
                CM.rms_dist_fit(i)=rms(H(~isout,:)*CM.Ax(:,i)-Xtest(~isout));
                
            end
            
            
            
            
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
        
        
        function fit_zp (CM,Args)
            arguments
                CM;
                Args.MinEpoch = numel(CM.MS.JD)*CM.ApearenceFactor;
                Args.UseWMedian = true;
                Args.RefImInd=2;
            end

            MagErr = 0.001*ones(size(CM.MS.Data.(CM.MagColName)));
            CM.MS.addMatrix(MagErr,'MagErr');
            res = lcUtil.zp_meddiff(CM.MS,'MagField',CM.MagColName,'MagErrField','MagErr',...
                'MinNepoch',Args.MinEpoch,'UseWMedian',Args.UseWMedian,'RefImInd',Args.RefImInd);
            CM.zp = res.FitZP';
            %res = lcUtil.zp_lsq(CM.MS,'MagField',CM.MagColName,'MagErrField','MagErr',...
            %    'MinNepoch',Args.MinEpoch);
            %CM.zp = res.FitZP;
            
            
        end
        
        
        function match_ogle_cat(CM,Args)
            arguments
                CM;
                Args.MatchRadius = 2;
                Args.UseWMedian = true;
                Args.RefImInd=2;
                Args.IncludeChi2 =false;
            end
            RefCat_ast = CM.create_reference(CM.MS.JD(1),'IncludeChi2',Args.IncludeChi2);
            Resultm1 = imProc.match.matchReturnIndices(RefCat_ast,CM.OgleCat,'Radius',Args.MatchRadius);
            CM.matched_flag_ogle_cat= Resultm1.Obj1_IndInObj2(~isnan(Resultm1.Obj1_IndInObj2));
            CM.matched_flag_ref_cat = Resultm1.Obj1_FlagNearest;
            xy_kmt = RefCat_ast.getCol({'X','Y'});
            xy_kmt = xy_kmt(CM.matched_flag_ref_cat,:);
            xy_ogle = CM.OgleCat.getCol({'X','Y'});
            xy_ogle = xy_ogle(CM.matched_flag_ogle_cat,:);
            [Result_aff,matched_pattern] = imProc.trans.fitPattern(xy_kmt,xy_ogle,'Scale',[0.8,1.2]...
                ,'RangeX',[-3,3],'RangeY',[-3,3],'StepX',0.05,'StepY',0.05,'MaxMethod','max1','SearchRadius',Args.MatchRadius,'Flip',[1 1]);
            [NewX,NewY]=imUtil.cat.affine2d_transformation([CM.OgleCat.getCol('X'),CM.OgleCat.getCol('Y')],Result_aff.Sol.AffineTran{1},'+'...
                   ,'ColX',1,'ColY',2);
            CM.OgleCat.Catalog(:,CM.OgleCat.colname2ind({'X','Y'})) = [NewX,NewY];
            Resultm2 = imProc.match.matchReturnIndices(RefCat_ast,CM.OgleCat,'Radius',Args.MatchRadius);
            CM.matched_flag_ogle_cat= Resultm2.Obj1_IndInObj2(~isnan(Resultm2.Obj1_IndInObj2));
            CM.matched_flag_ref_cat = Resultm2.Obj1_FlagNearest;
               
               
            
        end
        
        
        function fit_zp_ogle(CM,Args)
            arguments
                CM;
                Args.MatchRadius = 3;
                Args.UseWMedian = true;
                Args.RefImInd=2;
            end
            if isempty(CM.matched_flag_ref_cat) || isempty(CM.matched_flag_ref_cat)
                CM.match_ogle_cat;  
            end
            for EpochInd = 1:numel(CM.MS.JD)
                 
                %Result = imProc.match.matchReturnIndices(AstroCatalog({[CM.MS.Data.X(EpochInd,:)',CM.MS.Data.Y(EpochInd,:)']},'ColNames',{'X','Y'}),CM.OgleCat,'Radius',Args.MatchRadius);
                ogleI = CM.OgleCat.getCol('I');
                CM.zp(EpochInd) = tools.math.stat.rmean(CM.MS.Data.MAG_PSF(EpochInd,CM.matched_flag_ref_cat)' - ogleI(CM.matched_flag_ogle_cat),1);
            end
            CM.zp =reshape(CM.zp,[numel(CM.zp),1]) ;
        end    
            
        function fix_zp (CM)
            CM.MS.Data.(CM.MagColName)= CM.MS.Data.(CM.MagColName)-CM.zp;
            
        end
        
        
        

        function fit_pm (CM,Args)
            arguments
                CM
                Args.laterFlag=false;
                Args.JDlater=2458150 ;
                Args.Chi2DOFWeight = false;
                Args.WeightByPrcVsMag= false;
            end

            %H =
            CM.pm_x=[];
            CM.pm_y=[];
            CM.pm_x_err=[];
            CM.pm_y_err=[];
            H = [ones(size(CM.MS.JD)),CM.MS.JD - CM.RefJD];
            CM.revert_shift_scale;
            for Iobj = 1:CM.MS.Nsrc
                flux = CM.MS.Data.FLUX_PSF(:,Iobj);
                if Args.Chi2DOFWeight
                    chi2dof= CM.MS.Data.PSF_CHI2DOF(:,Iobj);
                    w= (flux.^2./chi2dof);
                elseif Args.WeightByPrcVsMag
                    w = (1./CM.MS.Data.err(:,Iobj)).^2;
                else
                    w= ones(size(flux));
                end
                if (Args.laterFlag)
                    Flag = ~isnan(CM.MS.Data.X(:,Iobj)) & ~isnan(CM.MS.Data.Y(:,Iobj)) & CM.MS.JD>Args.JDlater  ;
                else
                    Flag = ~isnan(CM.MS.Data.X(:,Iobj)) & ~isnan(CM.MS.Data.Y(:,Iobj)) & w>=0 ;
                end
                Xt = CM.MS.Data.X(Flag,Iobj);
                Yt = CM.MS.Data.Y(Flag,Iobj);
                wt = w(Flag);
                Ht = H(Flag,:);

                %fwhm = CM.MS.Data.fwhm(Flag,Iobj);
                fit_parx= lscov(H(Flag,:),Xt ,wt);
                fit_pary= lscov(H(Flag,:),Yt,wt);
                
                [~ ,rm_clip_x] = rmoutliers(Ht*fit_parx - Xt,'percentiles',[10,90]);
                [~ ,rm_clip_y] = rmoutliers(Ht*fit_pary - Yt,'percentiles',[10,90]);
                clip = rm_clip_y | rm_clip_x;
                
                [CM.pm_x(:,Iobj),CM.pm_x_err(:,Iobj)] = lscov(Ht(~clip,:),Xt(~clip),wt (~clip));
                [CM.pm_y(:,Iobj),CM.pm_y_err(:,Iobj)] = lscov(Ht(~clip,:),Yt(~clip),wt (~clip));
                
            end
        end
        

        function fit_pm_plx(CM,Args)
            % Fit proper motion and parallaxes for the relative astrometry
            % solution, i.e, measuren in pixels where the X axis is
            % parallel to the right ascesion and Y to declination.
            arguments
                CM
                Args.FitPlx =true;
                Args.ra_dec_ref=[]; % for pixesl no WCS solution [rad]
                Args.SigmaClip=false;
                Args.RefJD; % default is j2000
                Args.WeightByPrcVsMag = false;
            end

            
            [Ecoo,~] = celestial.SolarSys.calc_vsop87(CM.MS.JD, 'Earth', 'e', 'E');
            %[Res,Hra,Hdec,JD] = ml.astrometry.fit_pm_parallax_pix(Coo,JD,'ra_dec_ref',Args.ra_dec_ref,'FitPlx',Args.FitPlx);
            for Iobj = 1:CM.MS.Nsrc
                
                Flag = ~isnan(CM.MS.Data.X(:,Iobj)) & ~isnan(CM.MS.Data.Y(:,Iobj));
                Xt = CM.MS.Data.X(Flag,Iobj);
                Yt = CM.MS.Data.Y(Flag,Iobj);
                if Args.WeightByPrcVsMag 
                    w = (1./(400*CM.MS.Data.err(Flag,Iobj))).^2;
                else
                    w = ones(sizes(Xt));
                end
                Coo = [Xt,Yt];
                jd = CM.MS.JD(Flag);
                [Res,~,Hra,Hdec,jd] = ml.astrometry.fit_pm_parallax_pix(Coo,jd ,'ra_dec_ref',Args.ra_dec_ref,'FitPlx',Args.FitPlx,'Ecoo',Ecoo(:,Flag),'Weights',w);
                
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
                w= w(~clip);
                [Res,Err,Hra,Hdec] = ml.astrometry.fit_pm_parallax_pix(Coo,jd ,'ra_dec_ref',Args.ra_dec_ref,'FitPlx',Args.FitPlx,'Ecoo',ecoo_temp,'Weights',w );
                %CM.pm_x(:,Iobj) = Res(1:2);
                %CM.pm_x_err(:,Iobj) = Err(1:2);
                %CM.pm_y(:,Iobj) = Res(3:4);
                %CM.pm_y_err(:,Iobj) = Err(3:4);
                CM.plx_par(Iobj,:) = Res';
                CM.plx_par_err(Iobj,:) = Err';
                %CM.Hra_plx = Hra;
                %CM.Hdec_plx = Hdec;
                %[CM.pm_x(:,Iobj),CM.pm_x_err(:,Iobj)] = lscov(Ht(~clip,:),Xt(~clip),1./fwhm(~clip).^2);
                %[CM.pm_y(:,Iobj),CM.pm_y_err(:,Iobj)] = lscov(Ht(~clip,:),Yt(~clip),1./fwhm(~clip).^2);

            
            end
            
            
            
        end
        
                
        function fit_chromatic_ref(CM,Args)
            % Fit the first order of the chromatic refraction to the observerd residuals.
            %  C-med(C) secz sin\cos(pa) to the residuals of 
            arguments
                CM
                Args.FitPlx =true;
                %Args.ra_dec_ref=[]; % for pixesl no WCS solution [rad]
                Args.SigmaClip=false;
                Args.MaxMag = 18;
                Args.WeightByPrcVsMag = true;
                Args.prctile_Clip = [20,80];
            end
            expected_res = CM.MS.Data.err;%CM.resid_vs_mag_obj;
            expected_res = expected_res(:,CM.matched_flag_ref_cat);
            resx = CM.resid_per_obs_x;
            resx =resx(:,CM.matched_flag_ref_cat);
            resy = CM.resid_per_obs_y;
            resy =resy(:,CM.matched_flag_ref_cat);
            secz = CM.MS.Data.secz(:,CM.matched_flag_ref_cat);
            pa= CM.MS.Data.pa(:,CM.matched_flag_ref_cat);
            C= CM.OgleCat.getCol('V-I');
            C = C(CM.matched_flag_ogle_cat);
            magI= CM.OgleCat.getCol('I');
            magI = magI(CM.matched_flag_ogle_cat);
            
            id = ones(size(resx));
            
            C = id.*C';
            magI = id.*magI';
            
            
            flag_color = C(:)<8;
            
            flag_mag = magI(:)<Args.MaxMag;
            flag_res = ~(resx(:)> 2*expected_res(:) | resy(:)> 2*expected_res(:));
            flag_nan= ~isnan(C(:)) & ~isnan(magI(:))& ~isnan(resx(:))...
                & ~isnan(resy(:)) & ~isnan(expected_res(:)) & ~isnan(pa(:));
            flag = flag_mag & flag_color&flag_nan & flag_res;
            
            CM.C_med = median(C(:));
            C(:)= C(:)-CM.C_med;
            C = C(flag);
            secz= secz(flag);
            pa=pa(flag);
            resx = resx(flag);
            resy = resy(flag);
            
            H = [ones(size(C)),C.*secz .*cos(pa),...
                C.*secz .*sin(pa)];           
            dx_chrom_par = H\resx;
            dy_chrom_par = H\resy;
            
            
            out_x = isoutlier(resx - H*dx_chrom_par,'percentiles',Args.prctile_Clip);
            out_y = isoutlier(resy - H*dy_chrom_par,'percentiles',Args.prctile_Clip);
            
            outliers_xy= ~out_x & ~out_y;
            
            CM.dx_chrom_par = H(outliers_xy,:)\resx(outliers_xy);
            CM.dy_chrom_par = H(outliers_xy,:)\resy(outliers_xy);
            
            
            
            
        end
        
            
            
        
        
        function fit_simultaneous(CM,Args)
            
            arguments
                CM;
                Args.ra_dec_ref=[];
                Args.FitPlx = false;
                
                
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
               Args.WeightByPrcVsMag=true;
               Args.UseGlobalRef=true;
               Args.zp_ogle=true;
               Args.Chi2DOFWeight = false;
               Args.FitDistortion = false;
               Args.AffineOnlyOgle = false;
               Args.OnlyLowExpectedRes = false;
               Args.LowExpectedPrctl = 80;
               Args.MatchRadius = 1.5;
               Args.fitPatternMaxMag = [];
               Args.AffinePrctileRange = [20,80];
               Args.FitMaxOgleMag = [];
            end
            
            
            CM.MS.JD=[CM.AstCat.JD]';
            
            disp(['Finish catMatch construction'])
            CM.fit_pattern('MaxMag',Args.fitPatternMaxMag); CM.clear_pattern_failed;CM.apply_pattern;
            %CM.fit_pattern_match; CM.clear_pattern_failed;
            disp(['Finish pattern match'])
            try
                CM.MS.Data = rmfield(CM.MS.Data,'MagErr');
            catch
                do_nothing=0;
            end
            disp(['Start matching '])
            CM.matchCat('MatchRadius',Args.MatchRadius); CM.clear_unmatched;
            %CM.MS.addMatrix(CM.AstCat,CM.RetrunCols);
            %CM.clear_unmatched;
            disp(['finish matching '])
            
            %CM.fit_pm;
            %err_pattern= [CM.pm_x_err(1,:)',CM.pm_x_err(2,:)',CM.pm_y_err(1,:)',CM.pm_y_err(2,:)'];
            CM.fit_affine; CM.apply_affine;
            CM.fit_pm;
            %CM.fit_affine('GlobalRef',true,'OnlyMagRange',true);
            if Args.WeightByPrcVsMag
                CM.resid_vs_mag_obj;
            end
            if Args.AffineOnlyOgle
                CM.match_ogle_cat;
            end
            if Args.UseGlobalRef

                    CM.fit_affine('GlobalRef',true,'WeightByPrcVsMag',Args.WeightByPrcVsMag,'Chi2DOFWeight'...
                        ,Args.Chi2DOFWeight,'FlagChi2DOF',Args.Chi2DOFWeight,'OnlyOgle',Args.AffineOnlyOgle...
                        ,'PrctileRange',Args.AffinePrctileRange );
                    CM.apply_affine;
                    CM.fit_pm('WeightByPrcVsMag',Args.WeightByPrcVsMag,'Chi2DOFWeight',Args.Chi2DOFWeight);
            end
            %CM.apply_affine;
            if Args.FitPlx
                CM.fit_pm_plx('ra_dec_ref',[ra,dec],'WeightByPrcVsMag',Args.WeightByPrcVsMag);
            end
            
            %CM.fit_zp;CM.fix_zp;
            if Args.zp_ogle
                CM.fit_zp_ogle;
            else
                CM.fit_zp
            end 
            
            CM.fix_zp;
            
            if Args.FitDistortion
                CM.fit_distortion;
                CM.apply_distortion;
                CM.fit_pm('WeightByPrcVsMag',Args.WeightByPrcVsMag,'Chi2DOFWeight',Args.Chi2DOFWeight);
            end
        end
            
        
        
    end
    
    methods
        
        
        
        function [X,Y] = chromatic_corrected(CM,Args)
            
            arguments 
               CM; 
               Args.a= 1;
               
            end
            
            X =CM.MS.Data.X(:,CM.matched_flag_ref_cat);
            Y =CM.MS.Data.Y(:,CM.matched_flag_ref_cat);
            secz = CM.MS.Data.secz(:,CM.matched_flag_ref_cat);
            secz= secz(:);
            pa= CM.MS.Data.pa(:,CM.matched_flag_ref_cat);
            pa=pa(:);
            C= CM.OgleCat.getCol('V-I');
            C = C(CM.matched_flag_ogle_cat);
            
            id = ones(size(X));
            
            C = id.*C';
            C = C(:)-CM.C_med;
            C(C>9)=0;
            H = [ones(size(C)),C.*secz .*cos(pa),...
                C.*secz .*sin(pa)];           
            dx = H*CM.dx_chrom_par;
            dy = H*CM.dy_chrom_par;
            X(:) = X(:)-dx;
            Y(:) = Y(:)-dy;
            
            
            
        end
        
        
        function RefCat_ast = create_reference(CM,jd,Args)
            
            arguments
               CM;
               jd;
               Args.flag_pm_err=false;
               Args.IncludeChi2 = true;
            end
            jd0 = CM.RefJD;
            FLUX_PSF = mean(CM.MS.Data.FLUX_PSF,'omitnan')';
            MAG_PSF = mean(CM.MS.Data.MAG_PSF,'omitnan')';
            if Args.IncludeChi2
                PSF_CHI2DOF = mean(CM.MS.Data.PSF_CHI2DOF ,'omitnan')';
            end
            H = ones(size(MAG_PSF)).*[1,(jd - jd0)];
            X = diag(H*CM.pm_x);
            Y = diag(H*CM.pm_y);
            if Args.flag_pm_err
                flag = CM.get_flag_pm_err;
                X=X(flag); Y=Y(flag);MAG_PSF=MAG_PSF(flag);
                FLUX_PSF= FLUX_PSF(flag);
            end
            if Args.IncludeChi2
                RefCat_ast= AstroCatalog({[X,Y,MAG_PSF,FLUX_PSF,PSF_CHI2DOF]},'ColNames',{'X','Y','MAG_PSF','FLUX_PSF','PSF_CHI2DOF'});
            else
                RefCat_ast= AstroCatalog({[X,Y,MAG_PSF,FLUX_PSF]},'ColNames',{'X','Y','MAG_PSF','FLUX_PSF'});
            end
            
                
            
            
            
        end
        
        
        
        
        function H = distortion_design_matrix(CM,epochInd,Order,Args)
            % design matrix for Legendre polynomials fit
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
                Args.event_xy =  CM.pixelshift;
                
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
        
        
        
        function res = assym_rms(CM,Args)
            % function that calculate the assymptotic rms of each epochs
            % with respect to the global reference. 
            
            arguments 
                CM;
                Args.includeChi2=true;
                
            end
            res=zeros(numel(CM.MS.JD),1);
            for Eind = 1:numel(res)
                RefCat_ast = CM.create_reference(CM.MS.JD(Eind),'IncludeChi2',Args.includeChi2);
                XYref= RefCat_ast.getCol({'X'});
                res(Eind) = tools.math.stat.rstd(rmoutliers(XYref(:,1) - CM.MS.Data.X(Eind,:)','ThresholdFactor',2));
                
            end 
            
            
        end
        
        
        function resid_vs_mag_obj(CM,Args)
            arguments
                CM;
                Args=1;
            end
            err_mat = CM.resid_per_obs;
            mean_err_mat=nan(size(err_mat));
            for IndEpoch = 1:numel(CM.MS.JD)
                mag_ep = CM.MS.Data.MAG_PSF(1,:)';
                B = timeseries.binningFast([CM.MS.Data.MAG_PSF(IndEpoch ,:)', err_mat(IndEpoch,:)'], 0.3,[NaN NaN],{'MidBin', @median});
                if (IndEpoch == 287)
                    a= 1;
                end
                interp_w = interp1(B(:,1),B(:,2),mag_ep ,'linear');
                mean_err_mat(IndEpoch,:) = interp_w';
            end
            CM.MS.Data.err = err_mat;
            
        end
        
        function err_mat = resid_per_obs(CM,Args)
            arguments
                CM;
                Args=1;
            end
            
            
            err_mat = nan(size(CM.MS.Data.X));
            for IndEpoch = 1:numel(CM.MS.JD)
                refcat = CM.create_reference(CM.MS.JD(IndEpoch),'IncludeChi2',false);
                dxdy = [abs(refcat.getCol('X') - CM.MS.Data.X(IndEpoch,:)'),abs(refcat.getCol('Y') - CM.MS.Data.Y(IndEpoch,:)')];
                err_mat(IndEpoch,:) = mean(dxdy,2,'omitnan')';
                
                
            end
            
            
        end
        
        
        function err_mat = resid_per_obs_x(CM,Args)
            arguments
                CM;
                Args.ImInd=[];
            end
            
            
            
            if ~isempty(Args.ImInd)
                refcat = CM.create_reference(CM.MS.JD(Args.ImInd),'IncludeChi2',false);
                err_mat=  CM.MS.Data.X(Args.ImInd,:)'-refcat.getCol('X');
                
                
            else
                err_mat = nan(size(CM.MS.Data.X));
                for IndEpoch = 1:numel(CM.MS.JD)
                    
                    
                    refcat = CM.create_reference(CM.MS.JD(IndEpoch),'IncludeChi2',false);
                    err_mat(IndEpoch,:) =   CM.MS.Data.X(IndEpoch,:)'-refcat.getCol('X');
                end
                
            end
            
            
        end
        
        
        function err_mat = resid_per_obs_y(CM,Args)
            arguments
                CM;
                Args.ImInd=[];
            end
            
            
            if ~isempty(Args.ImInd)
                refcat = CM.create_reference(CM.MS.JD(Args.ImInd),'IncludeChi2',false);
                err_mat= CM.MS.Data.Y(Args.ImInd,:)'-refcat.getCol('Y');
                
                
            else
                err_mat = nan(size(CM.MS.Data.Y));
                for IndEpoch = 1:numel(CM.MS.JD)
                    
                    
                    refcat = CM.create_reference(CM.MS.JD(IndEpoch),'IncludeChi2',false);
                    err_mat(IndEpoch,:) =  CM.MS.Data.Y(IndEpoch,:)'-refcat.getCol('Y') ;
                end
                
            end
            
            
        end
        
        function prc_obj = precision_per_object(CM,Args)
            arguments
                CM;
                Args.Method='mean';
            end
            

            err_mat = CM.resid_per_obs;
            prc_obj = mean(err_mat,'omitnan');
            
            
            
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
        
        
        
        function Tab = source_table(CM,Args)
            
            
            arguments
                CM;
                Args.SrcInd= 1;
                Args.Col2return={'JD','X','Y','err','MAG_PSF','pmRA','pmDec','plx'};
            end
            Tab = [];
            Cat = nan(numel(CM.MS.JD),numel(Args.Col2return));
            for Ic = 1:numel(Args.Col2return)
                switch lower(Args.Col2return{Ic})
                    case 'jd'
                        Cat(:,Ic) = CM.MS.JD;
                        
                    case 'x'
                        Cat(:,Ic) = CM.MS.Data.X(:,Args.SrcInd);
                        
                    case 'y'
                        Cat(:,Ic) = CM.MS.Data.Y(:,Args.SrcInd);

                    case 'err'
                        Cat(:,Ic) = CM.MS.Data.err(:,Args.SrcInd);
                        
                    case 'mag_psf'
                        Cat(:,Ic) = CM.MS.Data.MAG_PSF(:,Args.SrcInd);
                    
                    case 'pmra'
                        Cat(:,Ic) = -ones(size(Cat(:,Ic))).*CM.pm_x(2,Args.SrcInd).*CM.pix2mas*365.25;
                        
                    case 'pmdec'
                        Cat(:,Ic) = ones(size(Cat(:,Ic))).*CM.pm_y(2,Args.SrcInd).*CM.pix2mas*365.25;
                    case 'plx'
                        Cat(:,Ic) = ones(size(Cat(:,Ic))).*CM.plx_par(Args.SrcInd,5).*CM.pix2mas;
                end
                
                Tab  = [Tab,table(Cat(:,Ic),'VariableNames',{Args.Col2return{Ic}})];
            end
            
            flag = all(~isnan(Cat),2);
            Tab = Tab(flag,:);
            
            
            
            
        end
        
        
        
        
    end
    
    
    
    methods % Plots and report
        
        
        
        function plot_lscov_prc(CM,Args)
            arguments
                CM;
                Args.plot= true;
                Args.ShowLegend=false;
                Args.ShowTitle =false;
                Args.prctile_th = 50;
                Args.magzp =0;
                Args.OnlyOgle = false;
                Args.Nbins = 20;
                Args.RmvOutliers = false;
                Args.closeall = true;
                Args.NewFigure = true;
                Args.sigma_clip = 2;
                Args.BinSize=0.7;
                Args.fun_prctl=[];
            end
            
            
            if (Args.closeall )
                close all;
            end
            
            if Args.NewFigure
                figure;
            end
            
            if isempty(Args.fun_prctl)
                Args.fun_prctl = @(x) prctile(x,Args.prctile_th);
            end
            
            pmx_err = CM.pm_x_err;
            mag = CM.MS.Data.MAG_PSF;
            if Args.OnlyOgle
                %x= x(:,CM.matched_flag_ref_cat);
                pmx_err =  pmx_err(:,CM.matched_flag_ref_cat);
                mag =  CM.OgleCat.getCol('I');
                mag = mag(CM.matched_flag_ogle_cat)';
                mag =repmat(mag, numel(pmx_err(1,:)),1) ;
                Args.magzp=0;
            end
            
    
            

            B = timeseries.binningFast([nanmean(mag)'+Args.magzp, pmx_err(1,:)'*400], Args.BinSize,[NaN NaN],{'MidBin', Args.fun_prctl, @tools.math.stat.rstd});
            %[xmid, ymid, loc, N] =  ut.calc_bin_fun(mag+Args.magzp ,,'Nbins',Args.Nbins ,'fun',Args.fun_prctl);
            if Args.RmvOutliers
                interp_w = interp1(B(:,1),B(:,2),nanmean(mag)','linear');
                interp_std = interp1(B(:,1),B(:,3),nanmean(mag)','nearest');
                flag_out= pmx_err(1,:)'*400< interp_w + Args.sigma_clip*interp_std;
                mag = mag(:,flag_out);
                pmx_err = pmx_err(:,flag_out);
                %x = x(:,flag_out);
                %pmx = pmx(:,flag_out);
            end
            
            semilogy(mean(mag,'omitnan')+Args.magzp ,pmx_err(1,:)'*CM.pix2mas,'.',...
                'MarkerSize',10,'HandleVisibility','off','Color',[0.5,0.5,0.9])
            
            hold on;
            xmid=B(:,1);
            ymid=B(:,2);
            semilogy(xmid,ymid,'DisplayName',[num2str(Args.prctile_th) '%'],'Color',[0.7,0.2,0.1],'LineWidth',2)
            
            
            set(gca,'YScale','log');
            ylabel('$\Delta $X (1D fit) [mas]','Interpreter','latex');
            xlabel('I [mag]','Interpreter','latex');
            box on;
            if(Args.ShowLegend)
                legend;
            end
            
            if(Args.ShowTitle)
                title('1D precision from lscov');
            end
            hold off;
            
            
            
        end
        
        
        function clip_by_prc_vs_mag(CM,Args)
            
            arguments
                CM;
                Args.prctile_th=50;
                Args.fun_prctl = [];%
                Args.sigma_clip=2;
            end
            
            if isempty(Args.fun_prctl)
                Args.fun_prctl = @(x) prctile(x,Args.prctile_th);
            end
            H = CM.pm_design_mat;
            mean_mag = mean(CM.MS.Data.MAG_PSF,'omitnan')';
            B = timeseries.binningFast([mean_mag, tools.math.stat.rstd(CM.MS.Data.X-H*CM.pm_x)'*0.4*1000], 0.4,[NaN NaN],{'MidBin', Args.fun_prctl, @tools.math.stat.rstd});
            interp_w = interp1(B(:,1),B(:,2),mean_mag ,'linear');
            interp_std = interp1(B(:,1),B(:,3),mean_mag ,'nearest');
            flag_out= tools.math.stat.rstd(CM.MS.Data.X-H*CM.pm_x)'*0.4*1000< interp_w + Args.sigma_clip*interp_std;
            CM.MS.Data = flag_struct_field(CM.MS.Data,flag_out,'FlagByCol',true);
            CM.pm_x = CM.pm_x(:,flag_out);
            CM.pm_y = CM.pm_y(:,flag_out);
            CM.pm_x_err = CM.pm_x_err(:,flag_out);
            CM.pm_y_err = CM.pm_y_err(:,flag_out);
            CM.plx_par = CM.plx_par(flag_out,:);
            CM.plx_par_err = CM.plx_par_err(flag_out,:);
            %CM.matched_flag_ref_cat = CM.matched_flag_ref_cat(flag_out);
            %CM.matched_flag_ogle_cat = CM.matched_flag_ogle_cat(flag_out);
            
        end
            
            
        function [meanmag,stdprc] = plot_rms_prc(CM,Args)
            arguments
                
                CM;
                Args.magzp = 0;
                Args.Nbin= 20;
                Args.prctile_th=50;
                Args.fun_prctl = [];%
                Args.OnlyOgle = false;
                Args.closeall = true;
                Args.Coo = [];
                %Args.Y = [];
                Args.pmx = [];
                Args.mag= [];
                Args.Nbins = 20;
                Args.NewFigure = true;
                Args.RmvOutliers = false;
                Args.sigma_clip = 2;
                Args.BinSize=0.7;
            end
            
            
            if (Args.closeall )
                close all;
            end
            
            if Args.NewFigure
                figure;
            end
            
            if isempty(Args.fun_prctl)
                Args.fun_prctl = @(x) prctile(x,Args.prctile_th);
            end
            magzp = Args.magzp;
            
            if ~isempty(Args.Coo ) & ~isempty(Args.pmx) & ~isempty(Args.mag)
                x= Args.Coo;
                pmx = Args.pmx;
                mag = Args.mag;
            else
                x= CM.MS.Data.X;
                pmx = CM.pm_x;
                mag = CM.MS.Data.MAG_PSF;
            end
            
            if Args.OnlyOgle
                x= x(:,CM.matched_flag_ref_cat);
                pmx =  pmx(:,CM.matched_flag_ref_cat);
                
                mag =  CM.OgleCat.getCol('I');
                mag = mag(CM.matched_flag_ogle_cat)';
                mag =repmat(mag, numel(x(:,1)),1) ;
                magzp=0;
            end
            
            H = CM.pm_design_mat;
            %flag_ast = CM.MS.Data.err(:,77)*400<40;
            %flag_ast=ones(size(CM.MS.Data.err(:,1)));
            is_out_x = isoutlier(x-H*pmx,'percentile',[10,90]);
            x(is_out_x)=nan;
            %jd = CM.MS.JD(~isout);
            mag(is_out_x)=nan;
            H = CM.pm_design_mat;
            
            
            B = timeseries.binningFast([nanmean(mag)'+magzp, tools.math.stat.rstd(x-H*pmx)'*0.4*1000], Args.BinSize,[NaN NaN],{'MidBin', Args.fun_prctl, @tools.math.stat.rstd});
            if Args.RmvOutliers
                interp_w = interp1(B(:,1),B(:,2),nanmean(mag)','linear');
                interp_std = interp1(B(:,1),B(:,3),nanmean(mag)','nearest');
                flag_out= tools.math.stat.rstd(x-H*pmx)'*0.4*1000< interp_w + Args.sigma_clip*interp_std;
                mag = mag(:,flag_out);
                x = x(:,flag_out);
                pmx = pmx(:,flag_out);
            end
            B = timeseries.binningFast([nanmean(mag)'+magzp, tools.math.stat.rstd(x-H*pmx)'*0.4*1000], Args.BinSize,[NaN NaN],{'MidBin', Args.fun_prctl, @tools.math.stat.rstd});
            meanmag =nanmean(mag)+magzp; 
            stdprc = tools.math.stat.rstd(x-H*pmx )*0.4*1000;
            semilogy(meanmag ,stdprc,'.'...
                ,'DisplayName','PM','MarkerSize',10,'HandleVisibility','off','Color',[0.5,0.5,0.9])
            hold on;
            
            xmid=B(:,1);
            ymid=B(:,2);
            semilogy(xmid, ymid,'DisplayName',[num2str(Args.prctile_th) '%'],'Color',[0.7,0.2,0.1],'LineWidth',2)
            xlabel('I [mag]','Interpreter','latex')
            ylabel('$\Delta$X (1D rstd) [mas]','Interpreter','latex')
            
            box on
            
        end
        
        function plot_cmd_ogle(CM,Args)
            arguments
                CM;
                
                Args.ShowLegend=true;
                Args.ShowTitle =true;
                Args.PlotHistogram=true;
                Args.ColorCut=2.5;
                Args.CloseAll=true;
                Args.MaxMag  (1,:) {mustBeNumeric}= [];
                Args.flagCat= true;
            end
            
            if(Args.CloseAll)
                close all;
            end
            V_I_og = CM.OgleCat.getCol('V-I');
            V_I_og  =V_I_og(CM.matched_flag_ogle_cat);
            plx = CM.plx_par(:,5)*400;
            plx(plx<0)=0;
            
            refAst = CM.create_reference(celestial.time.date2jd([2015,6,1]));
            mag_I_kmt = refAst.getCol('MAG_PSF');
            if Args.flagCat
                mag_I_kmt =mag_I_kmt(CM.matched_flag_ref_cat);
                plx = plx(CM.matched_flag_ref_cat);
            end
            flag = mag_I_kmt <21& V_I_og<9;
            if ~isempty(Args.MaxMag)
                flag = flag & mag_I_kmt<Args.MaxMag;
            end
            scatter(V_I_og(flag),mag_I_kmt(flag),[],plx(flag),'filled')
            set(gca,'YDir','reverse')
            ch= colorbar;
            ch.Limits = [0,max(plx(flag))];
            ylabel(ch,'q [mas]','Interpreter','latex')
            xlabel('V-I','Interpreter','latex')
            ylabel('I','Interpreter','latex')
            if Args.PlotHistogram
                if isempty(Args.ColorCut)
                    cut_color = median(V_I_og(flag));
                else
                    cut_color = Args.ColorCut;
                end
                
                
                figure;
                h= histogram(plx(V_I_og<cut_color),20,'FaceColor',[0.6,0.2,0.2],'DisplayName',['V-I < ' num2str(cut_color)],'Normalization','probability');
                hold on;
                histogram(plx(V_I_og>cut_color),'BinEdges',h.BinEdges,'FaceColor',[0.2,0.2,0.6],'DisplayName',['V-I > ' num2str(cut_color)],'Normalization','probability');
                if Args.ShowLegend
                    legend;
                end
            end
            
        end
        
        
        
        function plot_pm_scatter(CM,Args)
            
            arguments
                CM;
                Args.ShowLegend=true;
                Args.ShowTitle =true;
                Args.PlotHistogram=true;
                Args.ColorCut=[];
                Args.CloseAll=true;
                Args.MaxMag  (1,:) {mustBeNumeric}= [];
            end
            
            if(Args.CloseAll)
                close all;
            end

            pmx = CM.pm_x(2,:)'*CM.pix2mas * 365.25;
            pmy = CM.pm_y(2,:)'*CM.pix2mas * 365.25;
            
            plx = CM.plx_par(:,5)*400;
            plx(plx<0)=0;
            
            
            scatter(pmx,pmy,10,plx,'filled');
            
            
        end
        
        
        
        function plot_source_curves(CM,Args)
            arguments
                CM;
                Args.SourceInd= [];
                Args.ShowTitle =true;
                Args.PlotXY = true;
                Args.closeall=true;
            end
            if (Args.closeall)
                close all;
            end
            figure;
            if isempty(Args.SourceInd)
               Sind = CM.find_event_ind('event_xy',CM.pixelshift);
            else
                Sind =Args.SourceInd;
            end
            H = pm_design_mat(CM);
            ax1=subplot(3,1,1);
            plot(CM.MS.JD,CM.MS.Data.MAG_PSF(:,Sind),'.');
            ylabel('I [mag]')
            set(gca,'YDir','reverse')
            ax2= subplot(3,1,2);
            plot(CM.MS.JD,CM.MS.Data.X(:,Sind),'.');
            hold on;
            plot(CM.MS.JD,H*CM.pm_x(:,Sind));
            ylabel('X [pix]','interpreter','latex')
            hold off;
            ax3= subplot(3,1,3);
            plot(CM.MS.JD,CM.MS.Data.Y(:,Sind),'.');
            hold on;
            plot(CM.MS.JD,H*CM.pm_y(:,Sind));
            ylabel('Y [pix]')
            xlabel('jd');
            
            linkaxes([ax1,ax2,ax3],'x');
        end
        
        
        function plot_color_trends(CM,Args)
            arguments
                CM;
                Args.ImInd=1;
                Args.MaxMag=17;
                Args.closeall=true;
                Args.plot_all=true;
                Args.flagCat = true;
                Args.FlagPrcPrecentile= []; 
            end
            %CM.matched_flag_ogle_cat
            %CM.matched_flag_ref_cat
            if Args.closeall
                close all;
            end
            if Args.plot_all
                err_x= CM.resid_per_obs_x;
                err_y= CM.resid_per_obs_y;
                secz = CM.MS.Data.secz;
                pa = CM.MS.Data.pa;
                fwhm = CM.MS.Data.fwhm ;
                err_mag = CM.MS.Data.err;
                
                if Args.flagCat
                    err_x= err_x(:,CM.matched_flag_ref_cat);
                    err_y= err_y(:,CM.matched_flag_ref_cat);
                    secz = secz (:,CM.matched_flag_ref_cat);
                    pa = pa(:,CM.matched_flag_ref_cat);
                    fwhm =  fwhm(:,CM.matched_flag_ref_cat);
                    err_mag = err_mag(:,CM.matched_flag_ref_cat);
                end
                
                
                C = CM.OgleCat.getCol('V-I');
                I = CM.OgleCat.getCol('I');
                
                I= I(CM.matched_flag_ogle_cat);
                C= C(CM.matched_flag_ogle_cat);
                
                flag_I = I<Args.MaxMag ;

                err_x=err_x(:,flag_I);
                err_y=err_y(:,flag_I);
                secz = secz (:,flag_I);
                pa = pa(:,flag_I);
                fwhm= fwhm(:,flag_I);
                C= C(flag_I);
                
                err_mag= err_mag(:,flag_I);
                if ~isempty(Args.FlagPrcPrecentile)
                    prctile_err = prctile(err_mag,Args.FlagPrcPrecentile);
                    flag_prct = err_mag < prctile_err ;
                    err_mag(~flag_prct) = nan;
                    err_x(~flag_prct)= nan;
                    err_y(~flag_prct)= nan;
                    secz(~flag_prct)= nan;
                    pa(~flag_prct)= nan;
                    fwhm(~flag_prct)= nan;
                    %C= C(flag_prct);(flag_epoch)
                end
                Id = ones(size(err_x));
                C = Id.*C';
                C(C(:)>9) =0; 
                Color_t = C-median(C(:));
                
                %I= I(flag_I);
                
            else 
            
                err_x= CM.resid_per_obs_x('ImInd',Args.ImInd);
                err_y= CM.resid_per_obs_y('ImInd',Args.ImInd);
                err_x= err_x(CM.matched_flag_ref_cat);
                err_y= err_y(CM.matched_flag_ref_cat);
                
                secz = CM.MS.Data.secz(Args.ImInd,CM.matched_flag_ref_cat)';
                pa = CM.MS.Data.pa(Args.ImInd,CM.matched_flag_ref_cat)';
                C = CM.OgleCat.getCol('V-I');
                I = CM.OgleCat.getCol('I');
                I= I(CM.matched_flag_ogle_cat);
                C= C(CM.matched_flag_ogle_cat);
                
                flag_I = I<Args.MaxMag;
                secz=secz(flag_I);
                pa=pa(flag_I);
                err_x=err_x(flag_I);
                err_y=err_y(flag_I);
                C=C(flag_I);
                Color_t = C-median(C(:));
            
            end
            
            %flag_epoch = fwhm(:)<3.2;
            flag_epoch = true(size(fwhm(:)));
            figure;
            subplot(2,2,1)
            %semilogx(abs(err_x(:))*CM.pix2mas,Color_t (:).*secz(:).*cos(pa(:)),'.')
            plot(Color_t(flag_epoch).*secz(flag_epoch).*cos(pa(flag_epoch)),(err_x(flag_epoch))*CM.pix2mas,'.')
            xlabel('$AM \cdot C \cos(p)$','Interpreter','latex')
            %ylabel('$AM \cdot C $','Interpreter','latex')
            ylabel('$\Delta X$','Interpreter','latex')
            subplot(2,2,2)
            %semilogx(abs(err_x(:))*CM.pix2mas,Color_t (:).*secz(:).*sin(pa(:)),'.')
            plot(Color_t(flag_epoch).*secz(flag_epoch).*sin(pa(flag_epoch)),(err_x(flag_epoch))*CM.pix2mas,'.')
            %plot((err_x(:))*CM.pix2mas,Color_t(:).*sin(pa(:)),'.')
            xlabel('$AM \cdot C \sin(p)$','Interpreter','latex')
            ylabel('$\Delta X$','Interpreter','latex')
            subplot(2,2,3)
            %semilogx(abs(err_y(:))*CM.pix2mas,Color_t(:).*secz(:).*cos(pa(:)),'.')
            plot(Color_t(flag_epoch).*secz(flag_epoch).*cos(pa(flag_epoch)),(err_y(flag_epoch))*CM.pix2mas,'.')
            %plot((err_y(:))*CM.pix2mas,Color_t(:).*cos(pa(:)),'.')
            xlabel('$AM \cdot C \cos(p)$','Interpreter','latex')
            %ylabel('$AM \cdot C $','Interpreter','latex')
            ylabel('$\Delta Y$','Interpreter','latex')
            
            
            subplot(2,2,4   )
            %semilogx(abs(err_y(:))*CM.pix2mas,Color_t (:).*secz(:).*sin(pa(:)),'.')
            plot(Color_t(flag_epoch ).*secz(flag_epoch ).*sin(pa(flag_epoch )),(err_y(flag_epoch ))*CM.pix2mas,'.')
            %plot((err_y(:))*CM.pix2mas,Color_t(:).*sin(pa(:)),'.')
            xlabel('$AM \cdot C \sin(p)$','Interpreter','latex')
            ylabel('$\Delta Y$','Interpreter','latex')
        end
        
        function plot_ogle_mag_comparison(CM,Args)
            arguments
                CM;
                Args.closeall=true;
            end
            
            if Args.closeall
                close all;
            end
           mag_ogle= CM.OgleCat.getCol('I');
           mag_ogle = mag_ogle(CM.matched_flag_ogle_cat);
           
           mag_kmt = mean(CM.MS.Data.MAG_PSF,'omitnan')';
           mag_kmt  = mag_kmt(CM.matched_flag_ref_cat);
           plot(mag_kmt,mag_ogle,'.');
           xlabel('I - kmt')
           xlabel('I - ogle')
            
        end
        
        function compare_to_gaia(CM,Args)
            arguments
                CM;
                Args.CloseAll=true;
                Args.MaxMag = 16.5;
                Args.CatName = 'GAIADR2';
            end
            
            if (Args.CloseAll)
                close all;
            end
            %ogle_coo = CM.OgleCat.getCol({'RA','Dec'});
            %ogle_coo = ogle_coo(CM.matched_flag_ogle_cat,:);
            ra19 = '18:06:09.11' ;  Dec19 = '-26:04:41.20' ;
            ra=celestial.coo.convertdms(ra19,'SH','d');
            dec=celestial.coo.convertdms(Dec19,'SD','d');
            
            
            [AstrometricCat] = imProc.cat.getAstrometricCatalog(ra, dec, 'CatName',Args.CatName,...
                'Radius',4/60,...
                'RadiusUnits','deg',...
                'EpochOut',CM.MS.JD(1),...
                'argsProperMotion',{},...
                'ColNameMag','phot_rp_mean_mag',...
                'RangeMag',[0,20],...
                'ColNamePlx','Plx',...
                'RangePlx',[-50,100],...
                'OutRADecUnits','deg',...
                'UsePlxRange',false,...
                'RemoveNeighboors',false,...
                'argsProperMotion',{'ColRV',{'radial_velocity'}});%,...
            
            ogle_cat = CM.OgleCat.copy();
            ogle_cat.Catalog= ogle_cat.Catalog(CM.matched_flag_ogle_cat,:);
            Matched = imProc.match.matchedReturnCat(ogle_cat,AstrometricCat,'Radius',0.2);
            %Matched.Catalog= Matched.Catalog(CM.matched_flag_ogle_cat,:);
            
            kmt_pm_x  = CM.pm_x(2,CM.matched_flag_ref_cat)'*365.25*CM.pix2mas;
            kmt_pm_y  = CM.pm_y(2,CM.matched_flag_ref_cat)'*365.25*CM.pix2mas;
            magI = mean(CM.MS.Data.MAG_PSF(:,CM.matched_flag_ref_cat),'omitnan');
            flag = ~isnan(Matched.getCol('RA')) & ogle_cat.getCol('I')<Args.MaxMag;
            ogle_cat.Catalog = ogle_cat.Catalog(flag,:);
            kmt_pm_x = kmt_pm_x(flag);
            kmt_pm_y = kmt_pm_y(flag);
            Matched.Catalog= Matched.Catalog(flag,:);
            figure;
            errorbar(kmt_pm_y,Matched.getCol('PMDec'),Matched.getCol('ErrPMDec'),'.');
            xlabel('$\mu_{kmt}$ [mas]','Interpreter','latex')
            ylabel('$\mu_{gaia}$ [mas]','Interpreter','latex')
            figure;
            
            plot(ogle_cat.getCol('I'),Matched.getCol('phot_rp_mean_mag'),'.');
            
            
        end
            
        
        
        

        
    end
end