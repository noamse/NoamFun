function [ParE] = initiateParE(IF,Args)

arguments
    IF;
    Args.Chromatic = false;

end
%if IF.Chromatic 
%    ParE = zeros(8,IF.Nepoch);
%else
%    ParE = zeros(6,IF.Nepoch);
%end
ParE = zeros(6,IF.Nepoch);
if IF.AffSecondOrder
    ParE = zeros(12,IF.Nepoch);
end
end



