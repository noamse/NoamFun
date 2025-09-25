function [binIndex, N, RAedges, Decedges, meta] = binRADec(RA, Dec, opts)
% binRADec  2D binning of RA/Dec with a single bin ID per row.
% 
% Each input row gets exactly one index into the 2-D grid:
%   binIndex(k) = sub2ind([nDec nRA], decBin, raBin)   or 0 if out-of-range/NaN.
%
% Usage (R2021a+):
%   [binIndex, N, RAedges, Decedges, meta] = ut.binRADec(RA, Dec)
%   [binIndex, N, RAedges, Decedges] = ut.binRADec(RA, Dec, raBin=2, decBin=2)
%   [binIndex, N, RAedges, Decedges] = ut.binRADec(RA, Dec, units="hour")
%   [binIndex, N, RAedges, Decedges] = ut.binRADec(RA, Dec, weights=w)
%
% Inputs:
%   RA, Dec   : vectors (same length). Default units are degrees.
%               If RA is in hours, pass units="hour".
%
% Name-Value options:
%   raBin     : RA bin width in degrees (default 5)
%   decBin    : Dec bin height in degrees (default 5)
%   units     : "deg" (default) or "hour"  (RA*15 if "hour")
%   wrapRA    : wrap RA modulo 360 (default true)
%   raRange   : [min max] in deg for RA (default [0 360])
%   decRange  : [min max] in deg for Dec (default [-90 90])
%   weights   : optional weights per row (same length as RA/Dec). If given,
%               N accumulates weights; otherwise counts.
%   verbose   : print summary to console (default true)
%
% Outputs:
%   binIndex  : (numel(RA)×1) uint32. Linear bin index into N (Dec×RA), or 0.
%   N         : (#DecBins × #RABins) double (counts or sum of weights).
%   RAedges   : RA bin edges (deg), length nRA+1
%   Decedges  : Dec bin edges (deg), length nDec+1
%   meta      : struct with fields:
%                 .nRA, .nDec, .RAcenters, .Deccenters
%                 .units, .raBin, .decBin, .raRange, .decRange
%                 .validMask (finite RA/Dec & weights), .wrappedRA (RA after wrap/convert)
%                 .nPoints
%
% Notes:
%   - Binning uses MATLAB convention: [edge(k), edge(k+1)) except the last bin,
%     which is right-closed. Implemented with discretize().
%   - The linear index is in column-major (Dec first, RA second) consistent with N.

% ---------- signature & defaults ----------
arguments
    RA (:,1) double
    Dec (:,1) double
    opts.raBin   (1,1) double {mustBePositive} = 5
    opts.decBin  (1,1) double {mustBePositive} = 5
    opts.units   (1,1) string {mustBeMember(opts.units,["deg","hour"])} = "deg"
    opts.wrapRA  (1,1) logical = true
    opts.raRange (1,2) double = [0 360]
    opts.decRange(1,2) double = [-90 90]
    opts.weights double = []
    opts.verbose (1,1) logical = true
end

% ---------- cross-argument checks ----------
if opts.raRange(1) >= opts.raRange(2)
    error('binRADec:raRange','raRange must be [min max] with min < max.');
end
if opts.decRange(1) >= opts.decRange(2)
    error('binRADec:decRange','decRange must be [min max] with min < max.');
end
n = numel(RA);
if ~isempty(opts.weights) && numel(opts.weights) ~= n
    error('binRADec:weights','weights must match RA/Dec length.');
end

% ---------- prepare data (preserve original order/length) ----------
if opts.units == "hour"
    RAdeg = RA * 15;
else
    RAdeg = RA;
end
Decdeg = Dec;

% Validity mask (also include weights if provided)
valid = isfinite(RAdeg) & isfinite(Decdeg);
if ~isempty(opts.weights)
    w = opts.weights(:);
    valid = valid & isfinite(w);
else
    w = [];
end

% Wrap RA if requested (works for negatives as well)
if opts.wrapRA
    RAwrapped = mod(RAdeg, 360);
else
    RAwrapped = RAdeg;
end

% ---------- build bin edges ----------
RAedges  = opts.raRange(1):opts.raBin:opts.raRange(2);
Decedges = opts.decRange(1):opts.decBin:opts.decRange(2);
% Ensure exact right edge exists (important for discretize)
if RAedges(end)  < opts.raRange(2) - 1e-9,  RAedges(end+1)  = opts.raRange(2);  end
if Decedges(end) < opts.decRange(2) - 1e-9, Decedges(end+1) = opts.decRange(2); end
nRA  = numel(RAedges)  - 1;
nDec = numel(Decedges) - 1;

% ---------- per-row bin indices (no row is dropped) ----------
% discretize returns NaN for out-of-range; we convert to 0 later.
raIdx  = discretize(RAwrapped, RAedges);   % 1..nRA or NaN
decIdx = discretize(Decdeg,  Decedges);    % 1..nDec or NaN

% Combine into a single linear index (Dec × RA)
binIndex = zeros(n,1,'uint32');
maskIn = valid & ~isnan(raIdx) & ~isnan(decIdx);
if any(maskIn)
    binIndex(maskIn) = uint32(sub2ind([nDec, nRA], decIdx(maskIn), raIdx(maskIn)));
end
% All invalid/out-of-range rows remain 0.

% ---------- build the 2-D histogram N ----------
if isempty(w)
    % counts
    N = zeros(nDec, nRA);
    if any(maskIn)
        lin = double(binIndex(maskIn));  % 1..nDec*nRA
        N = accumarray(lin, 1, [nDec*nRA, 1], @sum, 0);
        N = reshape(N, [nDec, nRA]);
    end
else
    % weighted sum
    N = zeros(nDec, nRA);
    if any(maskIn)
        lin = double(binIndex(maskIn));
        N = accumarray(lin, w(maskIn), [nDec*nRA, 1], @sum, 0);
        N = reshape(N, [nDec, nRA]);
    end
end

% ---------- meta info ----------
RAcenters  = 0.5*(RAedges(1:end-1) + RAedges(2:end));
Deccenters = 0.5*(Decedges(1:end-1) + Decedges(2:end));
meta = struct( ...
    'nRA', nRA, 'nDec', nDec, ...
    'RAcenters', RAcenters, 'Deccenters', Deccenters, ...
    'units', string(opts.units), ...
    'raBin', opts.raBin, 'decBin', opts.decBin, ...
    'raRange', opts.raRange, 'decRange', opts.decRange, ...
    'validMask', valid, 'wrappedRA', RAwrapped, ...
    'nPoints', n );

% ---------- logging ----------
if opts.verbose
    fprintf('[binRADec] Rows: %d | Valid: %d | In-range: %d\n', ...
        n, nnz(valid), nnz(maskIn));
    fprintf('[binRADec] Grid: nDec=%d × nRA=%d (%.3g° × %.3g°)\n', ...
        nDec, nRA, opts.decBin, opts.raBin);
    fprintf('[binRADec] RA range: [%.4f, %.4f]° | Dec range: [%.4f, %.4f]°\n', ...
        opts.raRange(1), opts.raRange(2), opts.decRange(1), opts.decRange(2));
end
end
