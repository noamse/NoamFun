function [ParS] = initiateParS(IF,Args)

arguments
    IF;
    Args.Plx = true;
end

if IF.Plx
    ParS = zeros(5,IF.Nsrc);
else
    ParS = zeros(4,IF.Nsrc);
end
Xguess = IF.medianFieldSource({'X'});
Yguess = IF.medianFieldSource({'Y'});

ParS([1,2],:)= [Xguess';Yguess'];

end