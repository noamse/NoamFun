function print_loop_status(Index,ItNumber,varargin)

DefV.IterToPrint = 10;
DefV.massage='';
DefV.DoneAction='';

InPar = InArg.populate_keyval(DefV,varargin,mfilename);


if (mod(Index,InPar.IterToPrint)==0)
    disp([InPar.DoneAction '  ' str2num(Index) ' of  ' str2num(ItNumber) ]);
    if ~isempty(InPar.massage)
        disp(InPar.massage)
    end
end

end