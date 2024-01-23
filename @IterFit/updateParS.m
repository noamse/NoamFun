function updateParS(IF)


IF.ParS = IF.ParS+ reshape(IF.epsS,size(IF.ParS,1),size(IF.ParS,2));
end 