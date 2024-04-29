function [X,Y,RefCoo,Pars,ParsAffine,CooModel,JD,PA,C,RefractionAmp] = astrometrySim(Args)

arguments
    Args.Nsrc = 10;
    Args.Nepoch = 1000;
    Args.PMamplitude = 1/400;
    Args.Noise =1/200;
    Args.JD =[];
    Args.JD0 = 0;
    Args.AffineTranslationRange = [0,0];
    Args.AffineRotationRange = [0,0];
    Args.PlxExpMu = 1e-4;
    Args.CelestialCoo = [4.6273,-0.4646];
    Args.Chromatic =false;
    Args.Chrom2D = false;
    Args.Cmean = -0.5;
    Args.ChromaticRefractionAmp= 1e-4;
    Args.ChromaticRefractionAmpLognStd = 1e-2;
    Args.PAmean = pi/4;
    Args.PAstd = 0.005;
    
end

if isempty(Args.JD)
    jdrange = celestial.time.date2jd([2010,1,1;2020,1,1]);
    JD = linspace(jdrange(1),jdrange(2),Args.Nepoch)';
    if Args.JD0 ==0
        Args.JD0 = median(JD);
    end
else
    JD = Args.JD;
end
    


RefCoo = rand(Args.Nsrc,2)*100;
RefCoo = [RefCoo ones(size(RefCoo(:,1)))];

ProperMotionX = normrnd(0,Args.PMamplitude,[Args.Nsrc,1]);
ProperMotionY = normrnd(0,Args.PMamplitude,[Args.Nsrc,1]);
Plx = exprnd(Args.PlxExpMu,[Args.Nsrc,1]);

if ~all(Plx  ==0)
    [Ecoo] = celestial.SolarSys.calc_vsop87(JD, 'Earth', 'e', 'E');
    Xearth = Ecoo(1,:)'; Yearth = Ecoo(2,:)'; Zearth = Ecoo(3,:)';
else
    Xearth  = ones(Args.Nepoch,1);
    Yearth = ones(Args.Nepoch,1);
    Zearth = ones(Args.Nepoch,1);
    Ecoo = 0;
end

X = zeros(Args.Nsrc,Args.Nepoch);
Y = zeros(Args.Nsrc,Args.Nepoch);
%CooModel = zeros(Args.Nsrc,Args.Nepoch);
Pars= [RefCoo(:,1:2)';ProperMotionX';ProperMotionY';Plx';];

Xconst = Pars(1,:)'*ones(1,Args.Nepoch);
Yconst = Pars(2,:)'*ones(1,Args.Nepoch);

muX = Pars(3,:);
muY = Pars(4,:);

[Xpm,Ypm] = sim.astrometry.simPM(JD-Args.JD0,muX,muY);
if Ecoo ==0
    Xplx=0;
    Yplx=0;
else
    [Xplx,Yplx] = sim.astrometry.simPlx(Plx,Args.CelestialCoo,Ecoo);
end
Xnoise = normrnd(zeros(Args.Nsrc,Args.Nepoch),Args.Noise.*ones(Args.Nsrc,Args.Nepoch),Args.Nsrc,Args.Nepoch);
Ynoise = normrnd(zeros(Args.Nsrc,Args.Nepoch),Args.Noise.*ones(Args.Nsrc,Args.Nepoch),Args.Nsrc,Args.Nepoch);

CooModel.X = X;
CooModel.Y = Y;

X = Xconst+Xpm+Xplx;
Y = Yconst+Ypm+Yplx;


if ~Args.Chromatic
    X = Xconst+Xpm+Xplx;
    Y = Yconst+Ypm+Yplx;
    C=0;
    PA=0;
    RefractionAmp=0;
else
    C= rand(Args.Nsrc,1) + Args.Cmean;
    %C= C-median(C);
    %RefractionAmp= Args.ChromaticRefractionAmp.*lognrnd(0,Args.ChromaticRefractionAmpLognStd,1,Args.Nepoch);
    RefractionAmp= Args.ChromaticRefractionAmp.*abs(normrnd(1,0.1,1,Args.Nepoch));
    PA = normrnd(Args.PAmean,Args.PAstd,1,Args.Nepoch);
    [Xch,Ych,PA,C] = sim.astrometry.simChrom(RefractionAmp,C,PA);
    X = Xconst+Xpm+Xplx+Xch;
    Y = Yconst+Ypm+Yplx+Ych;
end


[X,Y,ParsAffine] = sim.astrometry.simAffineTran(X,Y,Args.Nepoch,'AffineRotationRange',Args.AffineRotationRange,...
    'AffineTranslationRange',Args.AffineTranslationRange);

X = X+Xnoise;
Y = Y+Ynoise;





% 
% for Iepoch = 1:Args.Nepoch
%     %PlxX= -(X.*sin(RA)- Y.*cos(RA)); 
%     %PlxY= (X.*cos(RA).*sin(RA) + Y.*sin(RA).*sin(Dec) - Z.*cos(Dec)); 
%     RA = Args.CelestialCoo(1);
%     Dec= Args.CelestialCoo(2);
%     RAPlxTerm= -Plx.*(Xearth(Iepoch).*sin(RA)- Yearth(Iepoch).*cos(RA)); 
%     DecPlxTerm= Plx.*(Xearth(Iepoch).*cos(RA).*sin(RA) + ...
%         Yearth(Iepoch).*sin(RA).*sin(Dec) - Zearth(Iepoch).*cos(Dec)); 
%     CooPM = RefCoo;
%     CooPM(:,1) = CooPM(:,1) + (JD(Iepoch)-Args.JD0)*ProperMotionX +RAPlxTerm;
%     CooPM(:,2) = CooPM(:,2) + (JD(Iepoch)-Args.JD0)*ProperMotionY +DecPlxTerm;
%     
%     CooModel(:,Iepoch) =CooPM(:,1);
%     tform =  randomAffine2d(Rotation=Args.AffineRotationRange,...
%         XTranslation=Args.AffineTranslationRange,YTranslation=Args.AffineTranslationRange);
%     AffineMat{Iepoch} = tform.T';
%     %AffineMat{Iepoch} = eye(3);
%     TAG = ((AffineMat{Iepoch})*CooPM')';
%     %TAG = ((eye(3))*CooPM')';
%     X(:,Iepoch) = TAG(:,1)+normrnd(0,Args.Noise, size(TAG(:,1)));
%     Y(:,Iepoch) = TAG(:,2)+normrnd(0,Args.Noise, size(TAG(:,1)));
% end
