function [S]= wfast_im_sim(impath,varargin)


DefV.im_h5opt='/images';
InPar = InArg.populate_keyval(DefV,varargin,mfilename);


S=SIM;

S.Im= h5read(impath,InPar.im_h5opt);
eHead =  ut.ghead2ehead(impath);
S.Header= eHead.Header;

end




