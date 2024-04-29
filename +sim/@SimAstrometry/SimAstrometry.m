classdef  SimAstrometry
%   This class generate an multi epoch astrometic simulated data.
%   
    
    properties
       X; Y; Epoch;
       ParS; ParE; ParC;
       epsS; epsE; epsC;
%       epsSTrack; epsETrack; epsCTrack;
%       AsX; AsY;
%       AeX; AeY;
%       bs; be; 
%       Nee; Nss; Nse;
%       N;
%       Ws; We; 
%       Wes;
%       PlxTerms;
%       Chromatic = false;
%       Plx = true;
    end
    
    
    methods
        function SA=SimAstrometry(varargin)
            %IF@MMS();
            %if nargin==1
            %    if isa(varargin{1},'MMS')
            %        meta=?MMS;
            %        dependent=[meta.PropertyList.Dependent];
            %        constant = [meta.PropertyList.Constant];
            %        props={meta.PropertyList.Name};
            %        for pname=props(~dependent & ~constant)
            %            eval(['IF.' pname{1} '=varargin{1}.' pname{1} ';']);
            %        end
            %    end
            %end
        end
    end
    
    
    
    
    methods
        
    end
    
    
    
end
    %{
    methods
        % getters and setters
        function Asx = get.AsX(IF)
            [Asx,~]   = generateSourceDesignMat(IF,'Plx',IF.Plx);
        end
        
        function Asy = get.AsY(IF)
            [~,Asy]   = generateSourceDesignMat(IF,'Plx',IF.Plx);
        end

        function Aex = get.AeX(IF)
                [Aex,~]   = generateEpochDesignMat(IF,'Chromatic',false);
        end
        
        function Aey = get.AeY(IF)
            [~,Aey]   = generateEpochDesignMat(IF,'Chromatic',false);
        end
        
        

        
        
    end
    methods
       % Populate variable

        [ParS]      = initiateParS(IF,Args);       
        [Asx,Asy]   = generateSourceDesignMat(IF);
        %[Asx,Asy]   = generateSourceDesignMatChrom(IF);
        
        [ParE]      = initiateParE(IF,Args);
        [Aex,Aey]   = generateEpochDesignMat(IF,Args);
        
        [Acx,Acy]   = generateChromDesignMat(IF,Args);
        
        [Nss]       = calculateNss(IF);
        [bs]        = calculateBs(IF);
        
        [Nee]       = calculateNee(IF);
        [be]        = calculateBe(IF);
        
        [Ncc]       = calculateNcc(IF);
        [bc]        = calculateBc(IF);
        
        [Wes]       = calculateWes(IF);
        [Ws]        = calculateWs(IF);
        [Rx,Ry]     = calculateResiduals(IF);
        [PlxX,PlxY] = calculatePlxTerms(IF);
       
        [Rx,Ry]     = updateResiduals(IF);
        
        
        
    end
    
    methods
        updateParS(IF);
        updateParE(IF);
        updateParC(IF);
        runIter(IF);
        startupIF(IF)
        
        
    end
    
    
    methods
        [Bx,By] =plotSource(IF,IndSrc)
        [RStdPrcX,RStdPrcY,M] = plotResRMS(IF,Args)
    end
end

    
    
    
    
%}