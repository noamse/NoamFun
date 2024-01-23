function RefCat = setOgleCat(AstCatPath, Args)

arguments
    AstCatPath;
    Args.OgleCatpath = '/data1/noamse/KMT/data/ob190506/ogle_ref_cat.mat';
    Args.SaveCat= true;
    Args.SavedCatFileName = 'RefCat.mat';
    Args.SettingFileName='master.txt';
    Args.OgleCat=[];
    Args.SetStruct = [];
end
if isempty(Args.SetStruct)
    Set = readtable([AstCatPath , Args.SettingFileName]);
    Set = table2struct(Set);
else
    Set = Args.SetStruct;
end


if isempty(Args.OgleCat)
    load(Args.OgleCatpath)
else
    RefCat = Args.OgleCat;
end

RefCat.sortrows('X');

flag_mag = RefCat.getCol('I')<Set.MaxRefMag;
RefCat.Catalog = RefCat.Catalog(flag_mag,:);
RefCat.Catalog(:,RefCat.colname2ind({'X','Y'})) = RefCat.Catalog(:,RefCat.colname2ind({'X','Y'}))- [Set.CCDSEC_xd,Set.CCDSEC_yd];

imsize = [Set.CCDSEC_xu - Set.CCDSEC_xd,Set.CCDSEC_yu - Set.CCDSEC_yd];
only_in_image = RefCat.Catalog(:,RefCat.colname2ind({'X'}))>Set.DistFromBound  ...
    & RefCat.Catalog(:,RefCat.colname2ind({'Y'}))> Set.DistFromBound &...
    RefCat.Catalog(:,RefCat.colname2ind({'X'}))<imsize(1)-Set.DistFromBound...
    &  RefCat.Catalog(:,RefCat.colname2ind({'Y'}))<imsize(1)-Set.DistFromBound ;
RefCat.Catalog = RefCat.Catalog(only_in_image,:);

D = sqrt((RefCat.getCol('X') - RefCat.getCol('X')').^2 + (RefCat.getCol('Y') - RefCat.getCol('Y')').^2);
D(logical(eye(size(D))))=inf;
Dmin  = min(D);
clear D;

flag = Dmin> Set.Dmin_thresh;
RefCat.Catalog = RefCat.Catalog(flag,:);

if Args.SaveCat
    save([AstCatPath Args.SavedCatFileName],'RefCat');
end
end