function Bpix = calculateBpix(IF,Args)
arguments
    IF;
    Args.FlagSource=[];
end



[ApixX,ApixY] = IF.generatePixDesignMat;

Wes = calculateWes(IF);
[Rx,Ry]     = IF.calculateResiduals;
if ~isempty(IF.FlagSourcesPix)
if ~isempty(IF.FlagSourcesPix)
    Wes(:,~IF.FlagSourcesPix)=0;
end
end
Wes = Wes(:);Rx= Rx(:); Ry= Ry(:);

OutNan = ~(isnan(ApixX(:,1))| isnan(Wes(:))| isnan(ApixY(:,1)));
%Wes = Wes(OutNan,:);ApixX= ApixX(OutNan,:); ApixY= ApixY(OutNan,:); 
%Rx= Rx(OutNan,:); Ry= Ry(OutNan,:);
Wes(~OutNan)=0;ApixX(~OutNan,:)=0; ApixY(~OutNan,:)=0; 
Rx(~OutNan,:)=0; Ry(~OutNan,:)=0;
Bpix = reshape(ApixX'*(Rx.*Wes) + ApixY'*(Ry.*Wes) ,[],1);





end