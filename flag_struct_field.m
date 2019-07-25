function st = flag_struct_field(st,Flag,varargin)
%{
apply Flag for struct fields

%}

DefV.Fields=[];
InPar = InArg.populate_keyval(DefV,varargin,mfilename);

if ~isempty(InPar.Fields)

    Fields = InPar.Fields;
else
    Fields = fieldnames(st);

end

for i = 1:numel(Fields)
    st.(Fields{i})  = st.(Fields{i})(Flag,:);
    
end


end