function Bhalat = calculateBhalat(IF)

%[Ax,Ay] = IF.generateSourceDesignMat;
[AhaX,AhaY] = generateHALatDesignMat(IF);

[Rx,Ry]     = IF.calculateResiduals;
Rx(isnan(Rx))= 0;
Ry(isnan(Ry))= 0;
Wes = calculateWes(IF);

Bhalat = reshape(AhaX'*(Rx.*Wes) + AhaY'*(Ry.*Wes) ,[],1);





end