function runSim(SA,Args)
arguments
    SA;
    Args.Plx=true;
    Args.JD = [];
end

if isempty(SA.JD)
    if ~isempty(Args.JD) 
        if numel(Args.JD)~=SA.NepochIn
            error('number of inserted JD different from NepochIn')
        end
        SA.JD = Args.JD;
    else
        SA.JD= SA.JD0 + (1:SA.NepochIn)' - SA.NepochIn/2;

    end
end

[PlxX,PlxY]= SA.calculatePlxTerms('Coo',SA.CelestialCoo);
SA.PlxTerms = [PlxX,PlxY];

SA.ParS = SA.initiateParS;
SA.ParE = SA.initiateParE;
[SA.Data.X,SA.Data.Y] = SA.generateXY;
[SA.Data.MAG_PSF,SA.Data.FLUX_PSF] = SA.generatePhotometry;

SA.applyParETran;



SA.ImageFileCell = SA.generateImages;




