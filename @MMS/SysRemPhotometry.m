function [CorrectedMag, SysRemSummary, SysEffect] = SysRemPhotometry(MMS, opts)
% SysRemPhotometry - Apply SysRem correction to a column of magnitudes in an MMS object
%
% Syntax:
%   [CorrectedObj, SysRemSummary, SysEffect] = SysRemPhotometry(MMS, opts)
%
% Description:
%   Applies the SysRem algorithm (Tamuz et al. 2005) to remove systematics
%   from a photometric data matrix in an MMS (or AstCat-like) object.
%   The magnitude column is specified via opts.ColNameMag.
%
% Inputs:
%   MMS       : Object with Data.<ColNameMag> field (e.g., MAG_PSF)
%   opts      : Name-value options:
%       - Sigma          : Error matrix (default = 1)
%       - Niter          : Number of SysRem iterations (default = 10)
%       - ThreshDeltaS2  : Convergence threshold (default = 0.01)
%       - ColNameMag     : Name of magnitude field (default = 'MAG_PSF')
%
% Outputs:
%   CorrectedObj    : MMS object with updated Data.<ColNameMag> field
%   SysRemSummary   : SysRem iteration outputs
%   SysEffect       : The additive correction that was subtracted
%
% Example:
%   [MMScorr, Summary, Sys] = SysRemPhotometry(IFsys, Niter=10, ColNameMag='MAG_AUTO');
%
% Author: Noam Segev, 2025
% -------------------------------------------------------------

arguments
    MMS;
    opts.Sigma = 1
    opts.Niter (1,1) double {mustBeInteger, mustBePositive} = 10
    opts.ThreshDeltaS2 (1,1) double {mustBeNonnegative} = 0.1
    opts.ColNameMag (1,1) string = "MAG_PSF"
end

ColName = opts.ColNameMag;

% Ensure the field exists
if ~isfield(MMS.Data, ColName)
    error('Field "%s" not found in MMS.Data.', ColName);
end

% Extract magnitude matrix
Mag = MMS.Data.(ColName);

% Subtract per-object median
CenteredMag = Mag - median(Mag, 'omitnan');

% Apply SysRem
[~, SysRemSummary] = timeSeries.detrend.sysrem(CenteredMag, opts.Sigma, ...
    'Niter', opts.Niter, 'ThreshDeltaS2', opts.ThreshDeltaS2);

% Reconstruct total systematic trend
[Nstar, Nepoch] = size(Mag);
SysEffect = zeros(Nstar, Nepoch);
for k = 2:numel(SysRemSummary)
    A = SysRemSummary(k).A;
    C = SysRemSummary(k).C;
    SysEffect = SysEffect + C * A;
end

% Apply correction
CorrectedMag = Mag - SysEffect;


end