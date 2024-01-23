function [Out]  = photometryOutliers(Obj,Args)
% Detect souces with bad photometry. Need to be used after zp correction.
arguments
    Obj;
    Args.SigmaClip = 2;
    Args.PrctileClip = [];%[10,90];
    
    
    
end


Mag= Obj.medianFieldSource({'MAG_PSF'});
RefMag= Obj.medianFieldSource({'RefMag'});

H = [ones(size(RefMag)),RefMag];
Par  = H\Mag;
MagErr = Mag-H*Par;
ErrPar = H\MagErr;

if ~isempty(Args.PrctileClip)
    Out=isoutlier(MagErr-H*ErrPar,'percentiles',Args.PrctileClip );
else 
    Delta = abs(MagErr-H*ErrPar);
    StdDelta = nanstd(Delta);
    Out =  Delta> Args.SigmaClip*StdDelta;
end
