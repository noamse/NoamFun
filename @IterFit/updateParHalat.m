function updateParHalat(IF)


IF.ParHalat = IF.ParHalat+ reshape(IF.epsHalat,size(IF.ParHalat,1),size(IF.ParHalat,2));
end 