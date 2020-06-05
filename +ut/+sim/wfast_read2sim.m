function [S]= wfast_read2sim(impath,varargin)
% Read a h5 image into a SIM object
% 
% Input : 
%        impath - path to the image location include the file name
%        
%        'im_h5opt' - the image attribute in the h5. Deafult: ' images'
%           '/stack' - in case images taken in stack mode
% 
% Output: 
%         S - SIM object contain the image and the header.
%               The function try to populate the wcs field

DefV.im_h5opt='/images';
InPar = InArg.populate_keyval(DefV,varargin,mfilename);


S=SIM;

S.Im= h5read(impath,InPar.im_h5opt);
eHead =  ut.h5head2Head(impath);
S.Header= eHead.Header;
S=populate_wcs(S);
end




