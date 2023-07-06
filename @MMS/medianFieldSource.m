function Tab = medianFieldSource(Obj,ColNames,Args)
arguments
    Obj;
    ColNames
    Args.a= 1;
end

Tab= nan(Obj.Nsrc,numel(ColNames));
for ICol =1:numel(ColNames)
    Tab(:,ICol)=median(Obj.getMatrix(ColNames{ICol}),'omitnan')';
end
