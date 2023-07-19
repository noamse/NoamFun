classdef MatchMS
    
    
    properties
        Cats = []
        PatternTrans = []; %cell array containing matrices of the affine fit.
        Failed =[];
        MatchedCats = [];
        %Tran2D = [] ; %Array of Tran2D object for sophisticated transformation.
        %PMX  = [] ; % x-axis proper motion model for each source
        %PMY  = [] ; % y-axis proper motion model for each source
        %PMErr = [];
        %ZP = []; % Fitted ZP. saved for performance.
        %JD0 = [];
        
        
    end
    
    
    
    methods
        [Res]= fitPattern(Obj,Args);
        [Trans,unPattern] = readPatternTrans(Obj,Res);
        Cats= applyPattern(Obj);
        MatchedMat = matchCats(Obj,Args);
        Flag = flagBad(Obj,Args);
        clearBad(Obj,Args);
        
    end
    
    
    methods
        
        [MatchedMat,JD]=mainRun(Obj,Cats);
    end
end