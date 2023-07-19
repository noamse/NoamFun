function [Trans,unPattern] = readPatternTrans(Res)


Trans = [Res.AffineTran];
unPattern = cellfun(@(x) numel(x)==9,Trans);



end
