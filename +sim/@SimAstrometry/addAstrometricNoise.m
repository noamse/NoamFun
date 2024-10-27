function addAstrometricNoise(SA,Args)

arguments
    SA;
    Args.NoiseType = 'gaussian';
    Args.Sigma = 1e-3;
    Args.Mu = 0;
end

if ~isempty(SA.NoiseAstSigma)
    Sigma = SA.NoiseAstSigma;
else
    Sigma = Args.Sigma;
end

NoiseX = normrnd(Args.Mu,Sigma ,size(SA.Data.X));
NoiseY = normrnd(Args.Mu,Sigma ,size(SA.Data.Y));

SA.Data.X = SA.Data.X+NoiseX ;
SA.Data.Y = SA.Data.Y+NoiseY ;