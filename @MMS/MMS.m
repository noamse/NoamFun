classdef  MMS < MatchedSources
  % Class def of MMS - Microlensing MatchedSources. This class is bulit to
  % suit for the astrometric microlesning experiment.
  
  
  
  properties
      AffineTrans = []; %cell array containing matrices of the affine fit. 
      Tran2D = [] ; %Array of Tran2D object for sophisticated transformation.
      PMX  = [] ; % x-axis proper motion model for each source
      PMY  = [] ; % y-axis proper motion model for each source
      ZP = []; % Fitted ZP. saved for performance. 
      JD0 = [];
      
  end
    methods
        
        
        function Result = get.JD0(Obj)
            Result = median(Obj.JD,'omitnan');
            Obj.JD0= Result;
            
        end
    end

    methods 
        %populateJD(Obj,MatchedMat,Args)
        Tab = medianFieldSource(obj,ColNames,Args);
        AffineMat= fitAffine(Obj,RefCoo,Args);
        applyAffineTran(Obj,AffineMat);
        ZP = fitRefZP(Obj,RefMagColName,Args)
        H = designMatrixEpoch(Obj,EpochInd,ColNames, FunCell);
        H = designMatrixPM(Obj,Args);
        Ind = findClosestSource(Obj,Coo);
        Flag = flagUnmached(Obj,Args); %Maybe implement imedietly? 
        mainRun(Obj,Args)
        [PMX,PMY,PMErr] = fitProperMotion(Obj,Args);
        TS = getTimeSeriesField(SourceInd,ColName,Args);
        
    end
    
    
    
   
end