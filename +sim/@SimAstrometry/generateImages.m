function [FileNames] = generateImages(SA,Args)
arguments
    SA;
    Args.SaveImages= true;
    Args.ImageTargetFolder = '/home/noamse/KMT/data/simulations/simulatedIM/'
    Args.ImageFileNameFormat = 'Image_%d.fits'
end


if isempty(SA.ImageTargetFolder)
    ImageTargetFolder = Args.ImageTargetFolder;
else
    ImageTargetFolder =SA.ImageTargetFolder;
end
ZEROIM = zeros(SA.Npix,SA.Npix);

% RefMag = SA.medianFieldSource({'MAG_PSF'});
% RefTab = [SA.ParS(1,:)',SA.ParS(2,:)',RefMag];
% RefCat = AstroCatalog({RefTab},'ColNames',{'X','Y',});
%save([ImageTargetFolder,'RefCat.mat'],'RefCat');
%
FileNames = cell(SA.Nepoch,1);
for Iepoch = 1:SA.Nepoch

    Im = AstroImage;
    Image = ZEROIM;
    %BackFlux = 10;
    % Generate epoch's catalog
    SrcCat = [SA.Data.X(Iepoch,:)',SA.Data.Y(Iepoch,:)',SA.Data.FLUX_PSF(Iepoch,:)'];
    % Generate PSF ## Change the parameters setting
    PSFCenter =ceil(SA.PSFStampSize/2);
    SrcPSF = imUtil.kernel2.gauss(4,[SA.PSFStampSize,SA.PSFStampSize],[PSFCenter ,PSFCenter ]);
    % Add noise 
    Image =Image  + poissrnd(SA.Background,size(Image,1),size(Image,2));
    % Inject sources
    
    Image =Image+ imUtil.art.injectSources(Image,SrcCat,SrcPSF ,'RecenterPSF',true);
    Im.Image=Image;
    Header = {'JD',SA.JD(Iepoch),'';};
    Im.HeaderData.insertKey(Header);
    FileNames{Iepoch} = [ImageTargetFolder,sprintf(Args.ImageFileNameFormat,Iepoch)];
    Im.write1(FileNames{Iepoch} ,'OverWrite',true);
    
end


end

