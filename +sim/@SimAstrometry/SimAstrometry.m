classdef  SimAstrometry< MMS
    %   This class generate an multi epoch astrometic simulated data.
    %

    properties
        X; Y;
        NsrcIn = 100; NepochIn=1000;
        mas2pix=400;
        CelestialCoo= [4.6273 -0.4646];
        ImageFileCell;
        Systematics;
        ParS; ParE; ParC;
        epsS; epsE; epsC;
        AeX;AeY;AsX;AsY;
        PlxTerms;
        Directory;
        ImageFilePaths;
        FileNameFormat;
        Npix=300;
        MuPM = [2,6]/400; SigmaPM=1/400;
        NoiseAstSigma= 1e-2;
        MuPlx = 1;
        Plx = true;
        AffineRotationRange = [-0.01,0.01]/180*pi;
        AffineTranslationRange = [-1,1]*1e-3;
        %Photometry pars
        MagRange    =[14,19]; Background=[10.^(-0.4*(21-25))]; MagStd=0.01;
        %PSF par
        PSFStampSize =15;
        %Logistics
        ImageTargetFolder ='/home/noamse/KMT/data/simulations/simulatedIM/';
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
    function Asx = get.AsX(SA)
        [Asx,~]   = generateSourceDesignMat(SA,'Plx',SA.Plx);
    end

    function Asy = get.AsY(SA)
        [~,Asy]   = generateSourceDesignMat(SA,'Plx',SA.Plx);
    end

    function Aex = get.AeX(SA)
        [Aex,~]   = generateEpochDesignMat(SA,'Chromatic',false);
    end

    function Aey = get.AeY(SA)
        [~,Aey]   = generateEpochDesignMat(SA,'Chromatic',false);
    end
end


    methods
        [ParS]      = initiateParS(SA,Args);
        [ParE]      = initiateParE(SA,Args);
        [X,Y]       = generateXY(SA,Args);
        [Mag,Flux]= generatePhotometry(SA,Args)
        [PlxX,PlxY] = calculatePlxTerms(SA,Args);
        [RefCat,RefTab] = generateRefCat(SA,Args);
    end

    methods
        
    end


    methods
        runSim(SA,Args)
        addAstrometricNoise(SA,Args)
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