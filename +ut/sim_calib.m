function S= sim_calib(S,Flat,Dark)
% Basic calibration of images. Reducing the dark and devide by the normalized flat.
% input: 
%   S- sim object, Flat, Dark - matrices
% example S= sim_calib(S,Flat,Dark)


%Flat.Im = double(Flat./mean(Flat(:)));

S.Im = (double(S.Im) - double(Dark))./Flat;

end