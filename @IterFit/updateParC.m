function updateParC(IF)


IF.ParC = IF.ParC+ reshape(IF.epsC,size(IF.ParC,1),size(IF.ParC,2));

end 