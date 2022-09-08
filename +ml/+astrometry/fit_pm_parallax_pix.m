function [Res,Err,Hra,Hdec,JD] = fit_pm_parallax_pix(Coo,JD,Args)
    % Fit the 2D proper motion together with annual parallax.
    
    
    
    
    
    arguments
        
       Coo;
       JD;
       Args.FitPlx =false;
       Args.ra_dec_ref=[]; % for pixesl no WCS solution
       Args.SigmaClip=false;
       Args.RefJD; % default is j2000
       Args.Ecoo=[];
    end
    
    
    
    
    %H = [ones(size(JD)),JD - Args.RefJD];
    
    
    
    jd2000= celestial.time.date2jd([2000,1,1]);
    if Args.FitPlx
        if isempty(Args.Ecoo)
            [Args.Ecoo,Vel] = celestial.SolarSys.calc_vsop87(JD, 'Earth', 'e', 'E');
        end
        X = Args.Ecoo(1,:)'; Y = Args.Ecoo(2,:)'; Z = Args.Ecoo(3,:)';
        ra_plx_term = X.*sin(Args.ra_dec_ref(1))- Y.*cos(Args.ra_dec_ref(1)); 
        dec_plx_term = X.*cos(Args.ra_dec_ref(1)).*sin(Args.ra_dec_ref(2)) + Y.*sin(Args.ra_dec_ref(1)).*sin(Args.ra_dec_ref(2)) - Z.*cos(Args.ra_dec_ref(2)) ; 
        Hra = [ones(size(JD)),JD-jd2000,zeros(size(JD)),zeros(size(JD)),ra_plx_term];
        Hdec = [zeros(size(JD)),zeros(size(JD)),ones(size(JD)),JD-jd2000,dec_plx_term];
        H = [Hra;Hdec];
        
        [Res,Err]=  lscov(H,[Coo(:,1);Coo(:,2)]);
        
    end
    
    
    
    
end