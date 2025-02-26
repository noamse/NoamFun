function updateRMSTrack(IF)

[RstdX,RstdY] = IF.calculateRstd;
IF.RMSTrack{end+1} = sqrt(RstdX.^2 + RstdY.^2);
%IF.ParS = IF.ParS+ reshape(IF.epsS,size(IF.ParS,1),size(IF.ParS,2));
end 