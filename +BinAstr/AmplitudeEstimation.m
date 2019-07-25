function Amp =  AmplitudeEstimation(D1,D2,a,d)

%return the value of the estimated amplitude of the COL rotation around the
%COM
% input : D1,D2 - diameters of the asteroids [km]
%         a     - semi major axis [km]
%         d     - distance from obsrever [au]
%
%output : estimated amplitude in miliarc


ampkm = a  .* ((D1.^3).*(D2.^2) - (D2.^3).*(D1.^2)   )./((D1.^3 + D2.^3).*(D1.^2+D2.^2));

ampRad= ampkm.*1e5  ./d./constant.au ;

Amp  =ampRad*3600*1000*180/pi  ; 
end 