function [S]= wfast_read2sim_dir(h5path,SavePath,varargin)
% TBD
% Read a h5 image into a SIM object and write it in SavePath
% 
% Input : 
%        h5path     - path to directory of wfast images
%        SavePath   - path to target .fits files
%        'im_h5opt' - the image attribute in the h5. Deafult: ' images'
%              '/stack' - in case images taken in stack mode
% 
% Output: 
%         files - List of saved files

DefV.im_h5opt='/images';
InPar = InArg.populate_keyval(DefV,varargin,mfilename);


S=SIM;

S.Im= h5read(impath,InPar.im_h5opt);
eHead =  ut.h5head2Head(impath);
S.Header= eHead.Header;
S=populate_wcs(S);
end
