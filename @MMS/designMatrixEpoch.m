function [H] = designMatrixEpoch(Obj,EpochInd,ColNames, FunCell)%, ColNameY, FunY, ColNameErrY, FunErrY)
% Generate desing matrix for selected epoch from MMS object.
% ? Add documentaion
arguments
    Obj
    EpochInd
    ColNames
    FunCell
    %ColNameY char
    %FunY             = @(x) ones(size(x));
    %ColNameErrY char = [];
    %FunErrY          = @(x) ones(size(x));
end

if ~iscell(FunCell)
    FunCell = {FunCell};
end
if ischar(ColNames)
    ColNames = {ColNames};
end

Nfun = numel(FunCell);
if Nfun~=numel(ColNames)
    error('FunCell and ColNames must contain the same number of elements');
end

Npt = Obj.Nsrc;
% design matrix
H   = nan(Npt, Nfun);
for Ifun=1:1:Nfun
    if isa(FunCell{Ifun}, 'function_handle')
        H(:,Ifun) = FunCell{Ifun}( Obj.Data.(ColNames{Ifun})(EpochInd,:) );
    else
        % functional may be [] -> ones, or number -> power
        if isempty(FunCell{Ifun})
            % ones
            H(:,Ifun) = ones(Npt,1);
        else
            % power
            H(:,Ifun) = Obj.Data.(ColNames{Ifun})(EpochInd,:).^FunCell{Ifun};
        end
    end
end
