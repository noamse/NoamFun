classdef  IterFit< MMS
    
    
    
    
    properties
       Rx; Ry;
       ParS; ParE; ParC;
       epsS; epsE; epsC;
       epsSTrack; epsETrack; epsCTrack;
       AsX; AsY;
       AeX; AeY;
       bs; be; 
       Nee; Nss; Nse;
       N;
       Ws; We; 
       Wes;
       PlxTerms;
       Chromatic = false; Chrom2D= true;
       Plx = true;
       UseWeights = true;
       CelestialCoo =  [4.6273,-0.4646];
       newWeights =false;
    end
    
    
    methods
        function IF=IterFit(varargin)
            IF@MMS();
            if nargin==1
                if isa(varargin{1},'MMS')
                    meta=?MMS;
                    dependent=[meta.PropertyList.Dependent];
                    constant = [meta.PropertyList.Constant];
                    props={meta.PropertyList.Name};
                    for pname=props(~dependent & ~constant)
                        eval(['IF.' pname{1} '=varargin{1}.' pname{1} ';']);
                    end
                end
            end
        end
    end
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
        [Hc]        = generateChromaticDesignMat(IF,Args)
        [Nss]       = calculateNss(IF);
        [bs]        = calculateBs(IF);
        
        [Nee]       = calculateNee(IF);
        [be]        = calculateBe(IF);
        
        
        [ParC]      = initiateParC(IF,Args);
        [Ncc]       = calculateNcc(IF);
        [bc]        = calculateBc(IF);
        
        [Wes]       = calculateWes(IF);
        [Ws]        = calculateWs(IF);
        [Rx,Ry]     = calculateResiduals(IF);
        [PlxX,PlxY] = calculatePlxTerms(IF,Args);
       
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
        [Chi2X,Chi2Y,NbinX,NbinY]= chi2Tests(IF,Args)
    end
end

    
    
    
    
