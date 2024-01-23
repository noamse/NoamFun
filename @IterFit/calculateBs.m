function Bs = calculateBs(IF)

%[Ax,Ay] = IF.generateSourceDesignMat;
Ax = IF.AsX;
Ay = IF.AsY;

[Rx,Ry]     = IF.calculateResiduals;
Rx(isnan(Rx))= 0;
Ry(isnan(Ry))= 0;
Wes = calculateWes(IF);

Bs = reshape(Ax'*(Rx'.*Wes) + Ay'*(Ry'.*Wes) ,[],1);





end