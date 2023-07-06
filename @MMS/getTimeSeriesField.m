function TS = getTimeSeriesField(Obj,SourceInd,ColNames,Args)

arguments
    Obj
    SourceInd = 1;
    ColNames = {'X','Y','MAG_PSF'};
    Args.ReturnColVector = true;
end

TS = nan(Obj.Nepoch,numel(ColNames));
for ICol = 1:numel(ColNames)
    TS(:,ICol) = Obj.Data.(ColNames{ICol})(:,SourceInd);
    
end

if ~Args.ReturnColVector
    TS=TS';
end