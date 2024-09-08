function [X,Y] = generateXY(SA,Args)

arguments
    SA;
    Args=1;
    
end


Asx =  SA.AsX;Asy = SA.AsY;



X = Asx*SA.ParS;
Y = Asy*SA.ParS;







