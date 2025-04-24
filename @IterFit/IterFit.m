classdef  IterFit< MMS




    properties
        Rx; Ry;
        ParS; ParE; ParC;ParHalat;ParPix;ParA;
        epsS; epsE; epsC; epsHalat;epsPix;epsA;
        epsSTrack; epsETrack; epsCTrack; epsHalatTrack;epsPixTrack;epsATrack;
        RMSTrack = {};
        AsX; AsY;
        AeX; AeY;
        bs; be;
        Nee; Nss; Nse;
        N;
        Ws; We;
        Wes;
        PlxTerms; 
        Chromatic = false; Chrom2D= false;
        HALat = false; PixPhase=false;
        Plx = true; FakePlx=false;AnnualEffect =false;
        UseWeights = true;
        CelestialCoo =  [4.6273,-0.4646];
        newWeights =false;
        AffSecondOrder = false; AffineNoOnes =false;
        ChromaicHighOrder = true;
        CBinWidth = 0.5;
        FlagSourcesPix= [];
        minUncerntainty = 2/400;
        InitialXYGuess=[]; 
        ContaminatingFlux=[];
    end


    methods
        function IF = IterFit(varargin)
            % Call the superclass constructor
            IF@MMS();

            % Check if the first argument is an MMS object
            if nargin >= 1
                if isa(varargin{1}, 'MMS')
                    % Copy properties from MMS
                    meta = ?MMS;
                    dependent = [meta.PropertyList.Dependent];
                    constant = [meta.PropertyList.Constant];
                    props = {meta.PropertyList.Name};
                    for pname = props(~dependent & ~constant)
                        eval(['IF.' pname{1} ' = varargin{1}.' pname{1} ';']);
                    end
                end
            end

            % Handle additional properties specific to IterFit
            if nargin > 1
                % Remaining arguments should be provided as name-value pairs
                for i = 2:2:nargin
                    if i+1 <= nargin
                        propName = varargin{i};
                        propValue = varargin{i+1};
                        if isprop(IF, propName)
                            IF.(propName) = propValue;
                        else
                            error('Property "%s" does not exist in class IterFit.', propName);
                        end
                    else
                        error('Property-value pair is incomplete.');
                    end
                end
            end
        end    end

    methods
        % getters and setters
        function Asx = get.AsX(IF)
            [Asx,~]   = generateSourceDesignMat(IF,'Plx',IF.Plx,'FakePlx',IF.FakePlx);
        end

        function Asy = get.AsY(IF)
            [~,Asy]   = generateSourceDesignMat(IF,'Plx',IF.Plx,'FakePlx',IF.FakePlx);
        end

        function Aex = get.AeX(IF)
            [Aex,~]   = generateEpochDesignMat(IF,'Chromatic',false);
        end

        function Aey = get.AeY(IF)
            [~,Aey]   = generateEpochDesignMat(IF,'Chromatic',false);
        end





    end

    methods (Static)
        IF = runIterFit(Obj,Args);


    end
    methods
        % Populate variable

        [ParS]      = initiateParS(IF,Args);
        [Asx,Asy]   = generateSourceDesignMat(IF);
        [Nss]       = calculateNss(IF);
        [bs]        = calculateBs(IF);
        [ParS]      = expandParSPlx(IF);

        [ParE]      = initiateParE(IF,Args);
        [Aex,Aey]   = generateEpochDesignMat(IF,Args);
        [Nee]       = calculateNee(IF);
        [be]        = calculateBe(IF);

        % [Acx,Acy]   = generateChromDesignMat(IF,Args);
        % [Acx,Acy,Ac]= generateChromaticDesign(IF,Args)
        % [ParC]      = initiateParC(IF,Args);
        % [Ncc]       = calculateNcc(IF);
        % [bc]        = calculateBc(IF);

        [ParHalat]      = initiateParHalat(IF,Args);
        [AhalatX,AhalatY]   = generateHALatDesignMat(IF,Args);
        [Nhalat]  = calculateNhalat(IF,Args);
        [Bhalat]  = calculateBhalat(IF,Args);

        [ParA]      = initiateParAnnual(IF,Args);
        [Aax,Aay]   = generateAnnualDesignMat(IF);
        [Naa]       = calculateNaa(IF);
        [ba]        = calculateBa(IF);


        %[Aax,Aay]   = generateAnnualDesignMatBins(IF);
        [Naa]       = calculateNaaBins(IF);
        [ba]        = calculateBaBins(IF);



        [Wes]       = calculateWes(IF,Args);
        [Ws]        = calculateWs(IF);
        [Rx,Ry]     = calculateResiduals(IF);
        [PlxX,PlxY] = calculatePlxTerms(IF,Args);

        [Rx,Ry]     = updateResiduals(IF);

        [RstdX,RstdY] = calculateRstd(IF);


        [ParHalat]      = initiateParHalatBins(IF,Args);
        [AhalatX,AhalatY]   = generateHALatDesignMatBins(IF,Args);
        [Nhalat]  = calculateNhalatBins(IF,Args);
        [Bhalat]  = calculateBhalatBins(IF,Args);
        [NC,edgesC,binC] = generateBins(C,Args);

        %
        % [ParPix]      = initiateParPix(IF,Args);
        % [ApixX,ApixY]   = generatePixDesignMat(IF,Args);
        % [Npix]  = calculateNpix(IF,Args);
        % [Bpix]  = calculateBpix(IF,Args);
    end

    methods
        updateParS(IF);
        updateParE(IF);
        updateParC(IF);
        updateParHalat(IF);
        updateParPix(IF);
        updateParHalatBins(IF);
        updateParAnnual(IF);
        updateParAnnualBins(IF)
        runIter(IF);
        runIterDetrend(IF);
        runIterBasic(IF);
        startupIF(IF);
        updateRMSTrack(IF);
        stopCondition(IF);
    end


    methods
        [Bx,By] =plotSource(IF,IndSrc)
        [RStdPrcX,RStdPrcY,M,RStdPrc] = plotResRMS(IF,Args)
        [Chi2X,Chi2Y,NbinX,NbinY]= chi2Tests(IF,Args)
    end
end





