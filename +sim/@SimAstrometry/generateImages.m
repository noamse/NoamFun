function [FileNames] = generateImages(SA,Args)
arguments
    SA;
    Args.SaveImages= true;
    Args.ImageTargetFolder = '/home/noamse/KMT/data/simulations/simulatedIM/'
    Args.ImageFileNameFormat = 'Image_%d.fits'
end



ZEROIM = zeros(SA.Npix,SA.Npix);
for Iepoch = 1:SA.Nepoch

    Im = AstroImage;
    Image = ZEROIM;
    BackFlux = 
    Image =Image  + poissrnd(BackFlux,size(Image,1),size(Im.Image,2));
    Image =Image+ imUtil.art.injectSources(Image,SrcCat,SrcPSF ,'RecenterPSF',false);
    Im.Image=Image;
    Header = {'JD',SA.JD(Iepoch),'';}
    Im.HeaderData.insertKey(Header)
    Im.write1([Args.ImageTargetFolder,sprinf(Args.ImageFileNameFormat,Iepoch)])
end

