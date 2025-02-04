function Ba = calculateBa(IF)

%[Ax,Ay] = IF.generateSourceDesignMat;
[Aax,Aay]   = generateAnnualDesignMat(IF);

[Rx,Ry]     = IF.calculateResiduals;
Rx(isnan(Rx))= 0;
Ry(isnan(Ry))= 0;
Wes = calculateWes(IF);

Ba = reshape(Aax'*(Rx.*Wes) + Aay'*(Ry.*Wes) ,[],1);





end