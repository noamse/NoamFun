function [MeanEpochLTC,MeanEpoch,MeanResAL,MeanResAL_err,MeanResAC,MeanScanPA,Lat,Long,distance] = readAstroidAstCat(Index,GAIADR2sso_obs,GAIADR2sso_orbit,GAIADR2sso_orbitres)
oldFolder = cd('/home/noamse/astro/binary_asteroid/horizon2/data/AsteroidCat') ;
A= dir('*.mat'); 
FileName={A(:).name};  
AsteroidNumber=Index;
StrOFsource = ['_' num2str(AsteroidNumber) '.mat'];
k = contains(FileName,StrOFsource);
IndexForSource = find(k~=0);
if sum(k)==0
    fprintf('No data for this asteroid \n');
    MeanEpochLTC=[]; MeanEpoch=[];MeanResAL=[]; MeanResAC=[];MeanScanPA=[]; Lat=[];
    Long=[]; distance=[];
    return;
end

for Isrc=IndexForSource 

    load(FileName{Isrc});
    if(isempty(ACat.Cat))
        fprintf('No data for this asteroid \n');
        MeanEpochLTC=[]; MeanEpoch=[];MeanResAL=[]; MeanResAC=[];MeanScanPA=[]; Lat=[];
        Long=[]; distance=[];
        return;
    end
    AstNumber = ACat.UserData.number_mp;
    obs_flag=find(AstNumber==GAIADR2sso_obs.Cat{:,GAIADR2sso_obs.Col.number_mp});
    orbit_flag=find(AstNumber==GAIADR2sso_orbit.Cat{:,GAIADR2sso_orbit.Col.number_mp});
    orbitres_flag=find(AstNumber==GAIADR2sso_orbitres.Cat{:,GAIADR2sso_orbitres.Col.number_mp});



    Objects_obs= GAIADR2sso_obs.Cat(obs_flag,:);
    Objects_orbit= GAIADR2sso_orbit.Cat(orbit_flag,:);
    Objects_orbitres= GAIADR2sso_orbitres.Cat(orbitres_flag,:);
    
    %Sort all the tables by observation id
    Objects_obs=  sortrows(Objects_obs,GAIADR2sso_obs.Col.observation_id);
    %Objects_orbit=  sortrows(Objects_orbit,GAIADR2sso_orbit.Col.observation_id)
    Objects_orbitres = sortrows(Objects_orbitres,GAIADR2sso_orbitres.Col.observation_id);
    
    
    Epoch0 = 2455197.5; % 2010.0 GAIA baricentric 0 point
    Epoch  = Objects_orbitres.epoch + Epoch0;  % JD TCB 
    ScanPA= Objects_obs.position_angle_scan;

    UniqueTransit = unique(Objects_orbitres.transit_id);
    Ntransit      = numel(UniqueTransit);
    Nep    = numel(Epoch);

    MeanResAL = zeros(Ntransit,1);
    MeanResAL_err = zeros(Ntransit,1);
    MeanResAC = zeros(Ntransit,1);
    NResAl    = zeros(Ntransit,1);
    MeanEpoch = zeros(Ntransit,1);
    MeanScanPA= zeros(Ntransit,1);
    for Itransit=1:1:Ntransit
        Itt = find(Objects_orbitres.transit_id == UniqueTransit(Itransit));
        if (length(Objects_orbitres.residual_al(Itt))<4)
            MeanResAL(Itransit)  = mean(Objects_orbitres.residual_al(Itt));
            MeanResAL_err(Itransit) = std(Objects_orbitres.residual_al(Itt))./(sqrt(numel(Itt)));
        else
            %MeanResAL(Itransit)  = Util.stat.rmean(Objects_orbitres.residual_al(Itt));
            %MeanResAL_err(Itransit) = Util.stat.rstd(Objects_orbitres.residual_al(Itt));
            MeanResAL(Itransit)  = mean(Objects_orbitres.residual_al(Itt));
            MeanResAL_err(Itransit) = std(Objects_orbitres.residual_al(Itt))./(sqrt(numel(Itt)));

        end
        MeanResAC(Itransit)  = mean(Objects_orbitres.residual_ac(Itt));
        NResAl(Itransit)     = numel(Itt);
        MeanEpoch(Itransit)  = mean(Epoch(Itt));
        MeanScanPA(Itransit) = mean(ScanPA(Itt));
    end


    LightTimeGrid   =   ACat.Cat(:,ACat.Col.LightTime_1w);
    EpochGrid       =   ACat.Cat(:,ACat.Col.JD);

    % Interpulate light time correction [minute]
    LightTime = interp1(EpochGrid,LightTimeGrid,MeanEpoch,'spline');

    %Convert light time [min] -> [sec]
    LightTime= LightTime *60;


    MeanEpochLTC  = MeanEpoch - LightTime./86400;

    %slice the epoches which not in the jpl range:  
    Flag =~isnan(MeanEpochLTC );
    MeanEpochLTC = MeanEpochLTC (Flag);
    MeanEpoch= MeanEpoch (Flag);
    MeanResAL= MeanResAL(Flag);
    MeanResAL_err= MeanResAL_err(Flag);
    MeanResAC= MeanResAC(Flag);
    MeanScanPA= MeanScanPA(Flag);

end

Lat=interp1(ACat.Cat(:,ACat.Col.JD),ACat.Cat(:,ACat.Col.ObsEcLat),MeanEpoch,'spline');
Long=interp1(ACat.Cat(:,ACat.Col.JD),ACat.Cat(:,ACat.Col.ObsEcLon),MeanEpoch,'spline');
Lat=Lat*pi/180;
Long=Long*pi/180;

distance = interp1(ACat.Cat(:,ACat.Col.JD),ACat.Cat(:,ACat.Col.Delta),MeanEpoch,'spline');
MeanScanPA= MeanScanPA*pi/180;

cd(oldFolder)
end