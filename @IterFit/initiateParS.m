function [ParS] = initiateParS(IF,Args)

arguments
    IF;
    Args.Plx = true;
end

if IF.Plx
    ParS = zeros(5,IF.Nsrc);
else
    ParS = zeros(4,IF.Nsrc);
%     if IF.FakePlx 
%         ParS = zeros(9,IF.Nsrc);
%     else
%         ParS = zeros(5,IF.Nsrc);
%     end
% elseif IF.FakePlx 
%     ParS = zeros(8,IF.Nsrc);
% else
%     ParS = zeros(4,IF.Nsrc);
end


Xguess = IF.medianFieldSource({'X'});
Yguess = IF.medianFieldSource({'Y'});

ParS([1,2],:)= [Xguess';Yguess'];

end