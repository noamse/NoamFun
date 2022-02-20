function [ResAst,OrigSim]=post_astrometry(Sim,varargin)
% Astrometric fit post astrometry.m. The function reproduce the
% astrometry.m fit and enable the implementation of covariances which
% includes different models to the astrometric fit.
%
% Input  : - An AstCat object or a SIM object includes astrometric
%   solution(WSC object).
%
% Output : - A structure array of astrometric solutions and quality
%            parameters for each image.
%
% Example: [ResAst,OrigSim]=ml.post_astrometry(S,varargin)

RAD = 180./pi;
CatField  = AstCat.CatField;
OrigColXY = {'dup_X','dup_Y'};

DefV.Scale              = 1.01; % arcsec/pix
switch Sim.WCS.CUNIT1
    
    case 'deg'
        DefV.RA                 = Sim.WCS.CRVAL1/RAD;   % rad,...
        DefV.Dec                = Sim.WCS.CRVAL2/RAD;   % rad,...
        
    case 'rad'
        DefV.RA                 = Sim.WCS.CRVAL1;   % rad,...
        DefV.Dec                = Sim.WCS.CRVAL2;   % rad,...
end

DefV.Equinox            = 2000.0;
DefV.RefCat             = 'GAIADR2';  %@get_ucac4; %@wget_ucac4;   % string, function, struct
DefV.RCrad              = 0.8./RAD; %0.8/RAD;   % [radian]
DefV.RefCatMagRange     = [14 19.0]; % 12 19.0];
DefV.ImSize = [];
DefV.ColXc              = {'XWIN_IMAGE','X','xpos'};
DefV.ColYc              = {'YWIN_IMAGE','Y','ypos'};

DefV.ApplyParallax      = true;
DefV.ApplyPM            = true;
DefV.RC_ColRA           = 'RA';
DefV.RC_ColDec          = 'Dec';
DefV.RC_ColPM_Dec       = 'PMDec';
DefV.RC_ColPM_RA        = 'PMRA';
DefV.RC_ColPM_Dec       = 'PMDec';
DefV.RC_ColPlx          = 'Plx';
DefV.RC_ColRV           = 'RV';
DefV.RC_ColMag          = 'Mag_RP';
DefV.RC_ColColor        = 'Mag_BP-Mag_RP';
DefV.RC_EpochInRA       = 'Epoch';
DefV.RC_EpochInDec      = 'Epoch';
DefV.RC_EpochInUnits    = 'yr';

DefV.Flip               = [1 -1]; %1 1];

DefV.BlockSize          = [512 512];
DefV.MinRot             = -15;
DefV.MaxRot             = +15;
DefV.StepRot            = 0.5;
DefV.BufferSize         = 200;

DefV.UseCase_TranC      = {'affine_tt_cheby2_4', 100; 'affine_tt_cheby2_3', 70; 'affine_tt',          10; 'affine',             5};
%maximum Excess noise in the reference catalog (GAIA)
DefV.MaxExcessNoise     = 10;
%threshold for proper motion errors(GAIA)
DefV.MaxPMerr           = [];

InPar = InArg.populate_keyval(DefV,varargin,mfilename);

% number of images
Nsim = numel(Sim);



if (~isempty(InPar.RA) && ~isempty(InPar.Dec))
    RA=InPar.RA;
    Dec=InPar.Dec;
else
    switch Sim.WCS.CUNIT1
        
        case 'deg'
            RA                 = Sim.WCS.CRVAL(1)/RAD;   % rad,...
            Dec                = Sim.WCS.CRVAL(2)/RAD;   % rad,...
            
        case 'rad'
            RA                 = Sim.WCS.CRVAL(1);   % rad,...
            Dec                = Sim.WCS.CRVAL(2);   % rad,...
    end
    
    
end



if (~isempty(InPar.ImSize))
    ImSize = InPar.ImSize;    % [X, Y]
else
    ImSize = imagesize(Sim);  % [X, Y]
end


if (AstCat.isastcat(InPar.RefCat) || isstruct(InPar.RefCat))
    % RefCat was provided
    RefCat = InPar.RefCat;
    
    % convert to AstCat object
    RefCat = AstCat.struct2astcat(RefCat);
else
    % External catalog was not provided
    % try to retrieve
    RefCat = VO.search.cat_cone(InPar.RefCat,RA(1),Dec(1),InPar.RCrad,'RadiusUnits','rad','OutType','astcat');
end



if (isempty(RefCat.Cat))
    % No reference catalog found - astrometric solution failed
    %ResAst(Isim) = [];
    warning('Reference catalog is empty - no solution found');
else
    % RefCat is not empty
    
    if isa(InPar.RefCat,'function_handle')
        RefCat = InPar.RefCat;
    else
        % clean the GAIA catalog
        switch lower(InPar.RefCat)
            
            case 'gaiadr2'
                MagG = col_get(RefCat,{InPar.RC_ColMag});
                ExcessNoise = col_get(RefCat,{'ExcessNoise'});
                F = ExcessNoise<InPar.MaxExcessNoise & MagG> InPar.RefCatMagRange(1) & MagG< InPar.RefCatMagRange(2);
                RefCat.(CatField) = RefCat.(CatField)(F,:);
                
                
        end
    end
end


if (InPar.ApplyPM)
    % applay proper motion, RV and parallax to star positions
    EpochOut = julday(Sim);  % get JD of image - (image epoch)
    %%% ----- !!!!!!!!!!!  ----- !!!!!!!!!!!!
    
    %The field 'ApplyParallax' added to the apply proper motion
    %call
    RefCat = apply_proper_motion(RefCat,'EpochInRA',InPar.RC_EpochInRA,...
        'EpochInDec',InPar.RC_EpochInDec,...
        'EpochInUnits',InPar.RC_EpochInUnits,...
        'EpochOut',EpochOut,...
        'EpochOutUnits','JD',...
        'ColPM_RA',InPar.RC_ColPM_RA,...
        'ColPM_Dec',InPar.RC_ColPM_Dec,...
        'ColPlx',InPar.RC_ColPlx,...
        'ColRV',InPar.RC_ColRV, ...
        'ApplyParallax', InPar.ApplyParallax);
    
    %apply the limit on the PM error (if given by the user)
    if (~isempty(InPar.MaxPMerr))
        IndForPMerr= RefCat.Cat(:,9)<InPar.MaxPMerr;
        RefCat.Cat=RefCat.Cat(IndForPMerr,:);
    end
    %%% ----- !!!!!!!!!!!  ----- !!!!!!!!!!!!
end




% Generate a version of the reference catalog with only selected columns
% RA, Dec, Mag, Color
[RC_ColRA, RC_ColDec, RC_ColMag] = colname2ind(RefCat,{InPar.RC_ColRA, InPar.RC_ColDec, InPar.RC_ColMag});
RC                = col_arith(RefCat,{InPar.RC_ColRA,InPar.RC_ColDec,...
    InPar.RC_ColMag,InPar.RC_ColColor},...
    'astcat',true);
RC.ColCell        = {InPar.RC_ColRA,InPar.RC_ColDec,'Mag','Color'};
RC_ColMag         = 3;   % Mag in 3rd column
RC                = colcell2col(RC);



Scale = InPar.Scale;
[X,Y]=projection(RC,'tan',[RC_ColRA RC_ColDec],[RAD.*3600./Scale RA Dec],'rad');
% add the projected X/Y as the 1st and 2nd columns in the reference catalog
ColRef   = {'X','Y'};
RC = col_insert(RC,X,1,'X');
RC = col_insert(RC,Y,2,'Y');
RC_ColMag         = 5;  % Mag is now in the 5th column!
% sort the reference catalog by the Y position
RC = sortrows(RC,'Y');

% clean sources out of image boundries
[~,ColXc]     = select_exist_colnames(Sim,InPar.ColXc(:));
[~,ColYc]     = select_exist_colnames(Sim,InPar.ColYc(:));
Isim= 1;
FlagIn = Sim.(CatField)(:,ColXc)>0 & ...
    Sim.(CatField)(:,ColXc)<ImSize(1) & ...
    Sim.(CatField)(:,ColYc)>0 & ...
    Sim.(CatField)(:,ColYc)<ImSize(2);
Sim.(CatField) = Sim.(CatField)(FlagIn,:);


% Removed from astrometry.m:
%   -clear lines
%   -clear over density
%   -change blocksize


BlockSize = InPar.BlockSize;
VecRot = (InPar.MinRot:InPar.StepRot:InPar.MaxRot).';



SimCat = AstCat.sim2astcat(Sim(Isim));

SimCat     = col_duplicate(SimCat,[ColXc,ColYc],OrigColXY);

% select sources in sub image
% If the solution is done in sub image then this generate
% a catalog for each sub image (block).

SubCat     = subcat_regional(SimCat,ImSize(Isim,:),BlockSize,InPar.BufferSize,[ColXc,ColYc]);
Nsub       = numel(SubCat);

ResBest    = Util.struct.struct_def({'MaxHistMatch','MaxHistShiftX','MaxHistShiftY',...
    'ShiftX','ShiftY','Tran','Nmatch','IndRef','IndCat',...
    'MatchedCat','MatchedRef','MatchedResid','StdResid',...
    'Std','MeanErr','BestRot','BestFlip'},Nsub,1);

ShiftRes = nan(Nsub,2);
ImCenter = ImSize(Isim,:).*0.5;


for Isub=1:1:Nsub
    %Isub
    % for each sub region
    
    % match ref catalog with image catalog
    % find also the correct image flip and rotation.
    % The origin of the reference catalog (RC) is [RA, Dec].
    % The origin of the image is its geometric center.
    % Note that the output MatchedCat
    % contains the columns: {'XWIN_IMAGE'  'YWIN_IMAGE'  'dup_X'  'dup_Y'}
    
    
    % SubCat contains sources in a sub image region
    % next line transform its coordinates from image corner to
    % image center (i.e., similar to that of the reference catalog)
    SubCat(Isub).(CatField)(:,[ColXc, ColYc]) = SubCat(Isub).(CatField)(:,[ColXc, ColYc]) - ImCenter;  % +[50 50];
    
    %
    %
    %
    % Set rotation bank and Scan
    %
    %
    if any(any(SubCat(Isub).(CatField)))
        ResRot = ImUtil.pattern.match_pattern_rot(SubCat(Isub).(CatField),RC.(CatField),...
            'CatColX',ColXc,...
            'CatColY',ColYc,...
            'HistDistEdges',InPar.HistDistEdges,...
            'CutRefCat',InPar.CutRefCat,...
            'SearchRangeX',InPar.SearchRangeX,...
            'SearchRangeY',InPar.SearchRangeY);
    else
        continue;
    end
    % go over all rotational possibilities
    Nrot = size(ResRot.MatchedRot,1);
    K = 0;
    VecRotSel = [];
    for Irot=1:1:Nrot
        if (any(all(ResRot.MatchedRot(Irot,3:4)==InPar.Flip,2)))
            K = K + 1;
            VecRotSel(K) = ResRot.MatchedRot(Irot,1);
        end
    end
    
    if (isempty(VecRotSel))
        % No rotation candidate solution found
        % go back to scanning
        VecRotSel = VecRot;
    else
        
        Fvrs = VecRotSel<InPar.MaxRot | (VecRotSel>InPar.MinRot | VecRotSel>(360+InPar.MinRot));
        VecRotSel = VecRotSel(Fvrs);
        %ImUtil.pattern.match_pattern_rot finds minus the rotation
        VecRotSel = -VecRotSel;
    end
    
    
    
    [Res,IndBest,H] = ImUtil.pattern.match_pattern_shift_rot(SubCat(Isub).(CatField),RC.(CatField),...
        VecRotSel,...
        'ColXc',ColXc,...
        'ColYc',ColYc,...
        'Flip',InPar.Flip,...
        'CutRefCat',InPar.CutRefCat,...
        'SearchRangeX',InPar.SearchRangeX,...
        'SearchRangeY',InPar.SearchRangeY,...
        'SearchRangeFactor',InPar.SearchRangeFactor,...
        'SearchStepX',InPar.SearchStepX,...
        'SearchStepY',InPar.SearchStepY,...
        'Radius',InPar.SearchRad);
    
    
    if (~isempty(Res) && ~isempty(IndBest))
        ShiftRes(Isub,:) = [Res(IndBest).ShiftX, Res(IndBest).ShiftY];
        
        ResSub(Isub) = Res(IndBest);
    end
    
end


MedianShift = nanmedian(ShiftRes,1);
FlagShift   = abs(ShiftRes - MedianShift)< (max(InPar.SearchStepX,InPar.SearchStepY).*5);
%FlagShift   = abs(ShiftRes - MedianShift)< (max(InPar.SearchStepX,InPar.SearchStepY).*50); % for LFC

SubGood     = and(FlagShift(:,1),FlagShift(:,2));
MatchedCat = [];
MatchedRef = [];

for Isub=1:1:Nsub
    % join the matched catalogs from the sub images
    if (SubGood(Isub))
        if (isempty(MatchedCat))
            MatchedCat = ResSub(Isub).MatchedCat;
            MatchedRef = ResSub(Isub).MatchedRef;
        else
            MatchedCat = [MatchedCat; ResSub(Isub).MatchedCat];
            MatchedRef = [MatchedRef; ResSub(Isub).MatchedRef];
        end
    end
end


if (isempty(MatchedRef) || isempty(MatchedCat))
    ResAst(Isim).ShiftRes = ShiftRes;
    ResAst(Isim).SubGood = any(SubGood);
else
    
    Nmatch = size(MatchedRef,1);
    
    % select transformation based on number of sources
    Iuse = find([InPar.UseCase_TranC{:,2}]<Nmatch,1);
    if (isempty(Iuse))
        error('Number of stars (Nmatch=%d) is too low for solution',Nmatch);
    end
    TranC = InPar.UseCase_TranC{Iuse,1};
    
    % A factor for normalizing the X/Y coordinates to unity
    NormXY = max(ImSize(Isim,:));
    
    CD = [1 0; 0 1].*Scale./3600;
    %!!!!!!!!!!!!!!!!!!!-----------------------!!!!!!!!!!!!!!!!!!!!!
    %clear many appearence of the same object.
    [indexes,ia,ic]=unique(MatchedCat(:,Sim(Isim).Col.IndexSimYsorted));
    MatchedRef=MatchedRef(ia,:);
    MatchedCat=MatchedCat(ia,:);
    %!!!!!!!!!!!!!!!!!!!-----------------------!!!!!!!!!!!!!!!!!!!!!
    
    MatchedRefCD        = MatchedRef;
    MatchedRefCD(:,1:2) = [CD*MatchedRefCD(:,1:2)']';
    MatchedCatCD        = MatchedCat;
    MatchedCatCD(:,[ColXc, ColYc]) = [CD*MatchedCatCD(:,[ColXc, ColYc])']';
    
    ResAst(Isim) = ImUtil.pattern.fit_transform(MatchedRefCD,MatchedCatCD,TranC,'ImSize',ImSize(Isim,:),...
        'BlockSize',InPar.AnalysisBlockSize,...
        'PixScale',InPar.Scale,...
        'CooUnits','deg',...
        'NormXY',1,...
        'ColCatX',ColXc,...
        'ColcatY',ColYc,...
        'PolyMagDeg',3,...
        'StepMag',0.1,...
        'Niter',InPar.Niter,...
        'SigClip',InPar.SigClip,...
        'MaxResid',InPar.MaxResid,...
        'Plot',InPar.Plot);
    
    
    ResAst(Isim).ShiftRes   = ShiftRes;
    ResAst(Isim).SubGood    = any(SubGood);
    %!!!!!!!!!!!!!!!!!!!-----------------------!!!!!!!!!!!!!!!!!!!!!
    %add the catalog data of the used objects with the cols data
    TempAstCat=AstCat;
    TempAstCat.Cat = MatchedCat(ResAst(Isim).FlagMag,:);
    TempAstCat.Col=SimCat.Col;
    TempAstCat.ColCell=SimCat.ColCell;
    ResAst(Isim).AstCat= TempAstCat;
    %indexes vector of the used objects in the original catalog
    ResAst(Isim).IndexInSim1=unique(MatchedCat(ResAst(Isim).FlagMag,ResAst(Isim).AstCat.Col.IndexSimYsorted));
    ResAst(Isim).IndexInSimN= ResAst(Isim).IndexInSim1(ResAst.FlagG);
    ResAst(Isim).FlagMag=[];
    %!!!!!!!!!!!!!!!!!!!-----------------------!!!!!!!!!!!!!!!!!!!!!
    
    %---------------------------------------------------------
    %--- Convert the transformation to WCS header keywords ---
    %---------------------------------------------------------
    % ImCenter - Coordinate zero in the image X/Y coordinate system
    % NormXY   - Coordinate normalization
    % RA,Dec   - assumed center [rad]
    
    %W = ClassWCS.tranclass2wcs(ResAst(Isim).TranC,'CooCenter',[RA,Dec], 'ImCenter',ImCenter, 'NormXY',NormXY, 'Scale',Scale);
    if (nargout>1)
        W = ClassWCS.tranclass2wcs_tpv(ResAst(Isim).TranC,'CooCenter',[RA,Dec], 'ImCenter',ImCenter, 'NormXY',NormXY, 'Scale',Scale,'CD',CD);
        OrigSim(Isim) = wcs2head(W,OrigSim(Isim));
        
        %add WCS field
        ResAst(Isim).WCS=OrigSim(Isim).WCS;
        
        % Vancky
        %add or update WCS field in OriginSim
        % it seems WCS in SIM is inherited from superclass WorldCooSys
        % thus xy2coo for SIM call function in WorldCooSys, need to
        % fix? now we have to W = ClassWCS.populate(OrigSim); and call
        % xy2coo(W,[X,Y]);
        ResAst(Isim).WCS  = W.WCS;
        OrigSim(Isim).WCS = W.WCS;
        
    end
    
    
    
    %Res(Isim).plot_resmag = @(Res) semilogy(Res(
end

end








