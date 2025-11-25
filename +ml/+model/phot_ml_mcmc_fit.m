function out = phot_ml_mcmc_fit(t, mag, mag_err, nsteps, varargin)
%PHOT_ML_MCMC_FIT  MCMC fit of a simple Paczynski microlensing model.
%
% INPUT:
%   t        : Nx1 time vector
%   mag      : Nx1 magnitudes
%   mag_err  : Nx1 magnitude uncertainties
%   nsteps   : number of MCMC steps (e.g. 50000)
%
% OPTIONAL NAME–VALUE:
%   'InitParams'     : [t0, u0, tE, Fbase, dF]
%   'StepScales'     : proposal widths
%   'ForceT0InSpan'  : enforce t0 inside [min(t), max(t)]  (default: true)
%   'tEBounds'       : [min_tE max_tE]  (default: [0.1 500])
%
% OUTPUT STRUCT:
%   out.chain       : MCMC samples
%   out.logpost     : log posterior values
%   out.accept_rate : fraction accepted
%   out.best_params : MAP parameters (t0,u0,tE,Fbase,dF)
%   out.model_flux  : model flux at MAP
%   out.model_mag   : model magnitudes
%   out.t_model     : cleaned time vector
%   out.data_mag    : cleaned magnitude vector
%   out.data_mag_err: cleaned magnitude uncertainties
%
% Microlensing model:
%   F(t) = Fbase + dF*(A(u(t)) - 1)
%   u(t) = sqrt( u0^2 + ((t - t0)/tE)^2 )
%   A(u) = (u^2+2)/(u*sqrt(u^2+4))

% -------------------------------------------------------------
% Parse inputs
% -------------------------------------------------------------
p = inputParser;
p.addParameter('InitParams',[],@(x)isnumeric(x)&&(isempty(x)||numel(x)==5));
p.addParameter('StepScales',[],@(x)isnumeric(x)&&(isempty(x)||numel(x)==5));
p.addParameter('ForceT0InSpan',true,@(x)islogical(x)||isnumeric(x));
p.addParameter('tEBounds',[0.1 500],@(v)isnumeric(v)&&numel(v)==2&&all(v>0));
p.parse(varargin{:});

p0_user       = p.Results.InitParams;
step_user     = p.Results.StepScales;
ForceT0InSpan = logical(p.Results.ForceT0InSpan);
tEBounds      = p.Results.tEBounds;

% -------------------------------------------------------------
% Clean inputs
% -------------------------------------------------------------
t   = t(:);
mag = mag(:);
if isempty(mag_err)
    mag_err = NaN(size(mag));
else
    mag_err = mag_err(:);
end

mask = isfinite(t) & isfinite(mag) & (isnan(mag_err) | isfinite(mag_err));
t       = t(mask);
mag     = mag(mask);
mag_err = mag_err(mask);

N = numel(t);
if N < 10
    error('Not enough valid data points.');
end

% -------------------------------------------------------------
% Convert magnitude → flux
% -------------------------------------------------------------
m0 = median(mag);
F  = 10.^(-0.4*(mag - m0));

if all(isnan(mag_err))
    sigF = ones(size(F));
else
    sigF = abs((log(10)/2.5) .* F .* mag_err);
    bad = ~isfinite(sigF) | sigF <= 0;
    sigF(bad) = median(sigF(~bad));
end

w = 1 ./ (sigF.^2);
w = w / max(w);

% -------------------------------------------------------------
% Time reference
% -------------------------------------------------------------
t_ref = median(t);
tt    = t - t_ref;

% -------------------------------------------------------------
% Microlensing model
% -------------------------------------------------------------
Afun   = @(u) (u.^2 + 2) ./ (u .* sqrt(u.^2 + 4));
u_of_t = @(par,tt_) sqrt(par(2)^2 + ((tt_ - par(1))/par(3)).^2);
Fmodel = @(par,tt_) par(4) + par(5)*(Afun(u_of_t(par,tt_)) - 1);

% -------------------------------------------------------------
% Priors
% -------------------------------------------------------------
tmin = min(tt);
tmax = max(tt);
if ForceT0InSpan
    t0_lb = tmin;
    t0_ub = tmax;
else
    t0_lb = tmin - 0.5*range(tt);
    t0_ub = tmax + 0.5*range(tt);
end

lb = [t0_lb, 1e-3, tEBounds(1),     0,          0];
ub = [t0_ub,   2,  tEBounds(2), 10*max(F), 10*max(F)];

logprior = @(p) box_logprior(p,lb,ub);
loglike  = @(p) microlens_loglike(p,tt,F,sigF,Fmodel);

% -------------------------------------------------------------
% Initial parameter guess
% -------------------------------------------------------------
if isempty(p0_user)
    [~, Ipk] = min(mag);
    t0_init = tt(Ipk);

    F_sorted = sort(F);
    Fb_init = median(F_sorted(1:round(0.3*N)));
    Fpeak   = max(F);
    dF_init = max(Fpeak - Fb_init, 0.1*Fb_init);

    u0_init = 0.1;
    tE_init = range(t)/10;

    p0 = [t0_init, u0_init, tE_init, Fb_init, dF_init];
else
    p0 = p0_user(:).';
end

p0 = min(max(p0,lb),ub);  % enforce prior bounds

% -------------------------------------------------------------
% Proposal scales
% -------------------------------------------------------------
if isempty(step_user)
    step_scales = [0.05*range(tt), 0.02, 0.1*range(t), 0.1*mean(F), 0.1*mean(F)];
else
    step_scales = step_user(:).';
end

% -------------------------------------------------------------
% MCMC loop
% -------------------------------------------------------------
npar = numel(p0);
chain   = zeros(nsteps,npar);
logpost = -inf(nsteps,1);

lp0 = logprior(p0);
ll0 = loglike(p0);
logpost(1) = lp0 + ll0;
chain(1,:) = p0;

n_acc = 0;

for i = 2:nsteps
    prop = chain(i-1,:) + randn(1,npar).*step_scales;

    lp = logprior(prop);
    if isinf(lp)
        chain(i,:) = chain(i-1,:);
        logpost(i) = logpost(i-1);
        continue;
    end

    ll = loglike(prop);
    lp_tot = lp + ll;

    if log(rand) < (lp_tot - logpost(i-1))
        chain(i,:) = prop;
        logpost(i) = lp_tot;
        n_acc = n_acc + 1;
    else
        chain(i,:) = chain(i-1,:);
        logpost(i) = logpost(i-1);
    end
end

accept_rate = n_acc / (nsteps-1);

% -------------------------------------------------------------
% MAP estimate (best posterior)
% -------------------------------------------------------------
[~, idx_best] = max(logpost);
best_rel = chain(idx_best,:);
best_abs = best_rel;     
best_abs(1) = best_rel(1) + t_ref;  

F_best = Fmodel(best_rel,tt);
model_mag = m0 - 2.5*log10(F_best);

% -------------------------------------------------------------
% Outputs
% -------------------------------------------------------------
out = struct();
out.chain       = chain;
out.logpost     = logpost;
out.accept_rate = accept_rate;

out.best_params = struct( ...
    't0',    best_abs(1), ...
    'u0',    best_abs(2), ...
    'tE',    best_abs(3), ...
    'Fbase', best_abs(4), ...
    'dF',    best_abs(5) );

out.model_flux = F_best;
out.model_mag  = model_mag;
out.t_model    = t;

% NEW: return original magnitudes aligned with t_model
out.data_mag     = mag;
out.data_mag_err = mag_err;

out.bounds      = struct('lb',lb,'ub',ub);
out.step_scales = step_scales;
out.t_ref       = t_ref;

end  % main function

% ============================================================
% Helper subfunctions
% ============================================================
function lp = box_logprior(p,lb,ub)
if any(p < lb) || any(p > ub)
    lp = -inf;
else
    lp = 0;
end
end

function ll = microlens_loglike(p,tt,F,sigF,Fmodel)
Fmod = Fmodel(p,tt);
res  = (F - Fmod) ./ sigF;
ll   = -0.5 * sum(res.^2 + log(2*pi*(sigF.^2)));
end
