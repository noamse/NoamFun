function st = flag_struct_field(st,Flag,Args)

% apply Flag for struct fields
% Input:
%         st - structure contain field to flag
%         
%         flag - a binary or 0,1 array
%         
%   Option:
%         'Field' - Cell array of field name (string)
%         'FlagByCol' - true to flag by column. default is false, i.e.,
%           flag by rows.
%   Example: st = flag_struct_field(st,Flag,'Field',{'JD','ALPHAWIN_J2000'});
% 
arguments
    st %Struct
    Flag %Flag
    Args.Fields = [];
    Args.FlagByCol=false;

end



if ~isempty(Args.Fields)

    Fields = Args.Fields;
else
    Fields = fieldnames(st);

end

for i = 1:numel(Fields)
    if Args.FlagByCol
        st.(Fields{i})  = st.(Fields{i})(:,Flag);
    else
        st.(Fields{i})  = st.(Fields{i})(Flag,:);
    end
    
    
end


end