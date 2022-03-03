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
        
        pixscale= 0.4; % arcsec/pix
        NormScale =200;
        pix2mas
        pixelshift = [607,606];
        isPixScaled = 0;
        % properties for MatchCat
        MatchRadius = 0.5 %
        RetrunCols = {'X','Y','MAG_CONV_1'...
                ,'SN_1','FLUX_CONV_1','MAGERR_CONV_1'...
                };%,'MAGERR_PSF'};
        Match_Summary;
        Match_N_Ep;
        MS = MatchedSources;
        MS_fields = {'X','Y','MAG_CONV_1','SN_1','FLUX_CONV_1','MAGERR_CONV_1'}
        ApearenceFactor=0.7;
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
                Ref = CM.AstCat(1);
            else
                Ref=CM.RefCat;
            end
        end
        
        
        function scale= get.pix2mas(CM)
            
           scale = CM.pixscale * CM.NormScale*1000 ;
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
            
            Flag =sum(~isnan(CM.MS.Data.X))>numel(CM.MS.JD)*CM.ApearenceFactor;
            CM.MS.Data= flag_struct_field(CM.MS.Data,Flag,'FlagByCol',true);
            
            
        end
        function fit_pattern(CM)
            % Fit pattren of the AstroCatalog array with respect to the
            % reference image, This procedure is rough with steps of 0.1
            % pixels.
            
            for IndCat = 1:numel(CM.AstCat)
                
                try
                    [II,Matched] = imProc.trans.fitPattern(CM.AstCat(IndCat),CM.RefCat,'StepX',1,'StepY',1,...
                        'RangeX',[-50.5,50.5],'RangeY',[-50.5,50.5]);
                    
                    CM.PatternMat{IndCat} =II.Sol.AffineTran;
                catch 
                    CM.Pattern_failed= [CM.Pattern_failed,IndCat];
                
                end
            end
            
    
        end
        
        function CM = clear_pattern_failed(CM)
            
            CM.AstCat(CM.Pattern_failed)=[];
            CM.PatternMat(CM.Pattern_failed)=[];
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
            SN = CM.MS.Data.SN_1;
            RefX = X(1,:);
            RefY = Y(1,:);
            for i =1:numel(CM.AstCat)
                %H = [X(i,:)',Y(i,:)',ones(size(RefX'))];
                H = CM.designMatrix(i,CM.AffineCols , CM.AffineFuns);
                Flag = ~isnan(X(i,:)')&~isnan(Y(i,:)') &~isnan(RefX')...
                    &~isnan(RefY');
                Ax = H(Flag,:)\RefX(Flag)';
                Ay = H(Flag,:)\RefY(Flag)';
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
                Flux = nanmean(CM.MS.Data.FLUX_CONV_1)';
                
            end
            if all(Flux==1)
                Flux = ones(size(nanmean(CM.MS.Data.FLUX_CONV_1)'));
            end
            % Fit for distortion using polynomials.
            RefX = CM.MS.Data.X(1,:)';
            RefY = CM.MS.Data.Y(1,:)';
            %[RefX,RefY]=CM.refXY;
            
            for i = 1:numel(CM.MS.JD)
                H = CM.distortion_design_matrix(i,CM.DistortionOrder);
                Flag = ~any(isnan(H),2) &~isnan(RefX)...
                    &~isnan(RefY);
                H= H(Flag,:);
                XrefT = RefX(Flag);
                YrefT = RefY(Flag);
                FluxT = Flux(Flag);
                ax = lscov(H,XrefT ,FluxT);
                ay = lscov(H,YrefT ,FluxT);
                isout= isoutlier(H*ax-CM.MS.Data.X(i,Flag)') | isoutlier(H*ay-CM.MS.Data.Y(i,Flag)');
                CM.Ax(:,i) = lscov(H(~isout,:),XrefT(~isout) ,FluxT(~isout));
                CM.Ay(:,i) = lscov(H(~isout,:),YrefT(~isout) ,FluxT(~isout));
            
                
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
        
        
    end
    
    
    
    methods 
    
        function H = distortion_design_matrix(CM,epochInd,Order)
            % 
            arguments 
               CM
               epochInd =1
               Order=3
                
            end
            X = CM.MS.Data.('X')(epochInd,:)';
            Y = CM.MS.Data.('Y')(epochInd,:)';
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
        
        
        function Result = fit_zp (CM)
            
            Result = lcUtil.zp_meddiff(CM.MS,'MagField','MAG_CONV_1','MagErrField','MAGERR_CONV_1');
            
            
            
        end
        
    end
end