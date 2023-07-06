function OM = flagPatternFail(OM,Args)
arguments
   OM 
   Args.Verbose = true;
    
end

if(Args.Verbose)
    disp([num2str(numel(OM.Pattern_failed)) '/' num2str(numel(OM.AstCat)) ...
        ' epochs were rejected via clear_pattern_failed' ])
end
OM.AstCat(OM.Pattern_failed)=[];
OM.PatternMat(OM.Pattern_failed)=[];
if ~isempty(OM.MS.JD)
    OM.MS.JD(OM.Pattern_failed)=[];
end

end
