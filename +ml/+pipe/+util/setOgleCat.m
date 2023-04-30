function ogle_cat = setOgleCat(AstCatPath, Args)

arguments
    AstCatPath;
    Args.OgleCatpath = '/data1/noamse/KMT/data/ob190506/ogle_ref_cat.mat';
    Args.SaveCat= true;
    Args.SavedCatFileName = 'ogle_cat.mat';
    Args.SettingFileName='master.txt';
end
Set = readtable([AstCatPath , Args.SettingFileName]);
Set = table2struct(Set);

load(Args.OgleCatpath)
ogle_cat.sortrows('X');

flag_mag = ogle_cat.getCol('I')<Set.max_I;
ogle_cat.Catalog = ogle_cat.Catalog(flag_mag,:);
ogle_cat.Catalog(:,ogle_cat.colname2ind({'X','Y'})) = ogle_cat.Catalog(:,ogle_cat.colname2ind({'X','Y'}))- [Set.CCDSEC_xd,Set.CCDSEC_yd];

imsize = [Set.CCDSEC_xu - Set.CCDSEC_xd,Set.CCDSEC_yu - Set.CCDSEC_yd];
only_in_image = ogle_cat.Catalog(:,ogle_cat.colname2ind({'X'}))>Set.DistFromBound  ...
    & ogle_cat.Catalog(:,ogle_cat.colname2ind({'Y'}))> Set.DistFromBound &...
    ogle_cat.Catalog(:,ogle_cat.colname2ind({'X'}))<imsize(1)-Set.DistFromBound...
    &  ogle_cat.Catalog(:,ogle_cat.colname2ind({'Y'}))<imsize(1)-Set.DistFromBound ;
ogle_cat.Catalog = ogle_cat.Catalog(only_in_image,:);

D = sqrt((ogle_cat.getCol('X') - ogle_cat.getCol('X')').^2 + (ogle_cat.getCol('Y') - ogle_cat.getCol('Y')').^2);
D(logical(eye(size(D))))=inf;
Dmin  = min(D);
clear D;

flag = Dmin> Set.Dmin_thresh;
ogle_cat.Catalog = ogle_cat.Catalog(flag,:);

if Args.SaveCat
    save([AstCatPath Args.SavedCatFileName],'ogle_cat');
end
end