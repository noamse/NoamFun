function eHead =  ghead2ehead(path,varargin)

% Convert WFAST hdf5 header to HEAD structure from the MAAT package. 
% Each row in the cell array represent attribute from WFAST header by
% {Key, Val, Description}

DefV.struct=[];
DefV.groups_fieldname = 'Groups';
DefV.attribute_fieldname = 'Attributes';
InPar = InArg.populate_keyval(DefV,varargin,mfilename);

eHead= HEAD;
attri = InPar.attribute_fieldname; 
groups=  InPar.groups_fieldname ;
Guy_st = h5info(path);


eHead= eHead.add_key(Guy_st.(groups).Name,' ',' ');
eHead= eHead.add_key('--','--','--');
eHead= read_add_attribute(eHead,Guy_st.(groups).(attri));


for i=1:numel(Guy_st.(groups).(groups))
    eHead= eHead.add_key('--','--','--');
    eHead= eHead.add_key(Guy_st.(groups).(groups)(i).Name,' ',' ');
    eHead= eHead.add_key('--','--','--');
    eHead= read_add_attribute(eHead,Guy_st.(groups).(groups)(i).(attri));
end
end


function [eHead] = read_add_attribute(eHead,attri)

    N = numel(attri);
    for Ind = 1:N
        if iscell(attri(Ind).Value)
            if iscell(attri(Ind).Value{1})
                val = cell2mat(attri(Ind).Value{1});
            else
                val = cell2mat(attri(Ind).Value);
            end
            
        else
            val = attri(Ind).Value;
        end
        if (or(isempty(val),isnan(val)))
           val=nan; 
        end
        if ~isnan(val)
            eHead= eHead.add_key(attri(Ind).Name,val,' ');
        end
    end

end