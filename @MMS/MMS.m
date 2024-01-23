classdef  MMS < MatchedSources & matlab.mixin.Copyable
    % Class def of MMS - Microlensing MatchedSources. This class is bulit to
    % suit for the astrometric microlesning experiment.
    
    
    
    properties
        AffineTrans = []; %cell array containing matrices of the affine fit.
        Tran2D = [] ; %Array of Tran2D object for sophisticated transformation.
        PMX  = [] ; % x-axis proper motion model for each source
        PMY  = [] ; % y-axis proper motion model for each source
        PMErr = [];
        ZP = []; % Fitted ZP. saved for performance.
        JD0 = [];
        PMPlx = [];
        PMPlxErr = [];
        
        
    end
    
    methods
        %populateJD(Obj,MatchedMat,Args)
        Tab             = medianFieldSource(obj,ColNames,Args);
        AffineMat       = fitAffine(Obj,RefCoo,Args);
        ZP              = fitRefZP(Obj,RefMagColName,Args)
        
        H               = designMatrixEpoch(Obj,EpochInd,ColNames, FunCell);
        H               = designMatrixPM(Obj,Args);
        [H]             = designMatPMPlxColor(Obj,Color,Coo,Args)
        
        Ind             = findClosestSource(Obj,Coo);
        Flag            = flagUnmached(Obj,Args); %Maybe implement imedietly?
        
        
        
        [PMX,PMY,PMErr] = fitProperMotion(Obj,Args);
        [PMPar,PMErr]   = fitProperMotionPlx(Obj,Args)
        [FullPar,FullParErr]   = fitPMPlxColor(Obj,Args);
        AffineMat       = fitAffinePMRef(Obj,XPMRef,YPMRef,Args);
        applyAffineTran(Obj,AffineMat);
        
        TS = getTimeSeriesField(SourceInd,ColName,Args);
        [XPMRef,YPMRef] = getGlobalRefMat(Obj);
        
        [Out]           = photometryOutliers(Obj,Args);
        applySourceFlag(Obj,Flag);
        [MatchedCat,FlagMatched]    = matchToRefCat(RefCat,Args);
        
        
        mainRun(Obj,MatchedMat,Args)
    end
    
    
    methods % plots
        [RStdPrcX,RStdPrcY] = plotPositionRMS(Obj,Args)
                              plotSourceCurves(Obj,Ind)
                              plotEtaTests(Obj)
        [Mag,MagErr,Out]    = plotMagErr(Obj);
                              plotCMDPlx(Obj,RefCat)
    end
    
    methods
        
        
        function Result = get.JD0(Obj)
            Result = median(Obj.JD,'omitnan');
            Obj.JD0= Result;
            
        end
    end
    
end