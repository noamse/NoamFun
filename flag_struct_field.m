function st = flag_struct_field(st,Flag,varargin)

% apply Flag for struct fields
% Input:
%         st - structure contain field to flag
%         
%         flag - a binary or 0,1 array
%         
%   Option:
%         'Field' - Cell array of field name (string)
%         
%   Example: st = flag_struct_field(st,Flag,'Field',{'JD','ALPHAWIN_J2000'});
% 


DefV.Fields=[];
DefV.FlagByCol=false;
InPar = InArg.populate_keyval(DefV,varargin,mfilename);

if ~isempty(InPar.Fields)

    Fields = InPar.Fields;
else
    Fields = fieldnames(st);

end

for i = 1:numel(Fields)
    if InPar.FlagByCol
        st.(Fields{i})  = st.(Fields{i})(:,Flag);
    else
        st.(Fields{i})  = st.(Fields{i})(Flag,:);
    end
    
    
end


end