classdef  MMS > MatchedSources
  % Class def of MMS - Microlensing MatchedSources. This class is bulit to
  % suit for the astrometric microlesning experiment.
  
  
  
  properties
      AffineTrans = []; %cell array containing matrices of the affine fit. 
      Tran2D = [] ; %Array of Tran2D object for sophisticated transformation.
      PM  = [] ; % proper motion model for each source
      ZP = []; % Fitted ZP. saved for performance. 
      
      
  end
    
  
    
  
  methods
      
      [H] = designMatrixEpoch(Obj,EpochInd,ColNames, FunCell)
      
  end
end