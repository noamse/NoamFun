function Result =fit_ml_phot(t,flux,Args)
    % Fit for photometric microlensing event. 
    %The function get a light curve and fit the photometric ml event by
    %matlab standard solvers.
    % Parameters: tE, t0, u0, fs, fb
    
    % Fit photometric without blending
    arguments
       t;
       flux;
       Args.err_flux= ones(size(flux));
       Args.Guess= [8543,20,0.15,1,1e-6];      
        
        
        
        
        
    end
    
    
    
    fun_min = @(X0) sumsqr((flux-ml.ml_flux(t,Args.Guess))./Args.err_flux); %X0 = [t0,tE,u0,fs]
    Result  = fminsearch(fun_min,Args.Guess);