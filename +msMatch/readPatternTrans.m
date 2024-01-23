function [Trans,FlagFailed] = readPatternTrans(Res)


Trans = [Res.AffineTran];
FlagFailed= cellfun(@(x) numel(x)==9,Trans);



end
