function out = phot_ml_smooth_peak_fit(t, mag, mag_err, opts)
%PHOT_ML_SMOOTH_PEAK_FIT  
% Weighted smoothing of a microlensing photometric time series + peak detection.
%
% INPUT:
%   t        - time vector
%   mag      - magnitude vector
%   mag_err  - magnitude uncertainties (can be empty or NaN)
%   opts     - structure or name-value with fields:
%       .SpanDays   - half-width of the smoothing window (days)
%       .PolyOrder  - local polynomial order (0–3)
%
% OUTPUT:
%   out.t_model        - cleaned time vector
%   out.model_mag      - smoothed magnitude model
%   out.data_mag       - cleaned magnitudes
%   out.data_mag_err   - cleaned uncertainties
%   out.t0             - peak time estimate
%   out.ind0           - index of peak
%   out.mag0           - magnitude at peak (smoothed)

arguments
    t (:,1) double
    mag (:,1) double
    mag_err (:,1) double = nan(size(mag))

    opts.SpanDays (1,1) double {mustBePositive} = 20
    opts.PolyOrder (1,1) double {mustBeInteger, mustBeGreaterThanOrEqual(opts.PolyOrder,0), mustBeLessThanOrEqual(opts.PolyOrder,3)} = 2
end

SpanDays  = opts.SpanDays;
PolyOrder = opts.PolyOrder;

% -------------------------------------------------------------
% Clean inputs
% -------------------------------------------------------------
mask = isfinite(t) & isfinite(mag) & (isnan(mag_err) | isfinite(mag_err));
t       = t(mask);
mag     = mag(mask);
mag_err = mag_err(mask);

N = numel(t);
if N < PolyOrder + 2
    error('Not enough valid data points for the requested polynomial order.');
end

% -------------------------------------------------------------
% Build weights
% -------------------------------------------------------------
if all(isnan(mag_err))
    w = ones(N,1);
else
    w = 1 ./ (mag_err.^2);
    w(~isfinite(w) | w<=0) = 0;
    if all(w==0)
        w = ones(N,1);
    end
    w = w / max(w);
end

% -------------------------------------------------------------
% Default smoothing range
% -------------------------------------------------------------
if isnan(SpanDays)
    SpanDays = range(t) / 20;
end

% -------------------------------------------------------------
% Weighted local polynomial smoothing
% -------------------------------------------------------------
model_mag = nan(N,1);

for i = 1:N
    idx = abs(t - t(i)) <= SpanDays;
    ti  = t(idx);
    yi  = mag(idx);
    wi  = w(idx);

    if numel(ti) < PolyOrder + 1
        model_mag(i) = mag(i);
        continue;
    end

    dt_i = ti - t(i);

    % Polynomial basis X = [1, dt, dt^2, ...]
    X = ones(numel(dt_i), PolyOrder+1);
    for k = 1:PolyOrder
        X(:,k+1) = dt_i.^k;
    end

    W = diag(wi);
    XtW = X' * W;

    beta = (XtW * X) \ (XtW * yi);

    model_mag(i) = beta(1);
end

% -------------------------------------------------------------
% Peak detection on smoothed curve
% -------------------------------------------------------------
[mag0, ind0] = min(model_mag);
t0 = t(ind0);

% -------------------------------------------------------------
% Output
% -------------------------------------------------------------
out = struct();
out.t_model        = t;
out.model_mag      = model_mag;
out.data_mag       = mag;
out.data_mag_err   = mag_err;
out.t0             = t0;
out.ind0           = ind0;
out.mag0           = mag0;

end
